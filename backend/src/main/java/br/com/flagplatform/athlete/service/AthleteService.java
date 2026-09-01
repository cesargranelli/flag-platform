package br.com.flagplatform.athlete.service;

import br.com.flagplatform.athlete.AthleteInfo;
import br.com.flagplatform.athlete.AthleteLookup;
import br.com.flagplatform.athlete.dto.request.CreateAthleteRequest;
import br.com.flagplatform.athlete.dto.request.CreateAthleteBatchItem;
import br.com.flagplatform.athlete.dto.request.CreateAthleteBatchRequest;
import br.com.flagplatform.athlete.dto.request.UpdateAthleteRequest;
import br.com.flagplatform.athlete.dto.response.AthleteResponse;
import br.com.flagplatform.athlete.dto.response.AthleteBatchLineResult;
import br.com.flagplatform.athlete.dto.response.AthleteBatchResponse;
import br.com.flagplatform.athlete.entity.AthleteEntity;
import br.com.flagplatform.athlete.exception.AthleteNotFoundException;
import br.com.flagplatform.athlete.exception.InvalidAthletePositionsException;
import br.com.flagplatform.athlete.mapper.AthleteMapper;
import br.com.flagplatform.athlete.repository.AthleteRepository;
import br.com.flagplatform.common.enums.AthletePosition;
import br.com.flagplatform.common.enums.AthleteStatus;
import br.com.flagplatform.common.enums.DocumentType;
import br.com.flagplatform.common.exception.DuplicateDocumentException;
import br.com.flagplatform.common.exception.InvalidDocumentException;
import br.com.flagplatform.common.pagination.PagedResponse;
import br.com.flagplatform.common.validation.DocumentValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class AthleteService implements AthleteLookup {

    private static final int MAX_POSITIONS = 3;

    private final AthleteMapper mapper;
    private final AthleteRepository repository;

    @Transactional
    public AthleteResponse create(CreateAthleteRequest request) {
        validateCpf(request.cpf(), null);
        List<AthletePosition> positions = validatePositions(request.positions());
        AthleteEntity entity = mapper.toEntity(request);
        entity.setPositions(positions);
        entity.setStatus(AthleteStatus.ACTIVE);
        return mapper.toResponse(repository.save(entity));
    }

    /**
     * Valida uma carga em lote sem gravar (dry-run). Retorna o resultado por
     * linha: {@code VALID}, {@code DUPLICATE} (nome ja existe) ou {@code INVALID}
     * (nome em branco). Linhas validas sao retornadas para pre-visualizacao.
     */
    public AthleteBatchResponse validateBatch(CreateAthleteBatchRequest request) {
        List<AthleteBatchLineResult> lines = new ArrayList<>();
        int valid = 0;
        for (int i = 0; i < request.athletes().size(); i++) {
            CreateAthleteBatchItem item = request.athletes().get(i);
            int line = i + 2; // linha 1 = cabecalho
            if (item.name() == null || item.name().isBlank()) {
                lines.add(new AthleteBatchLineResult(line, "INVALID", "Informe o nome", item));
            } else if (item.cpf() == null || !DocumentValidator.isValid(item.cpf(), DocumentType.CPF)) {
                lines.add(new AthleteBatchLineResult(line, "INVALID", "CPF inválido", item));
            } else if (repository.existsByCpf(item.cpf().replaceAll("\\D", ""))) {
                lines.add(new AthleteBatchLineResult(line, "DUPLICATE", "CPF já cadastrado", item));
            } else if (repository.existsByNameIgnoreCase(item.name().trim())) {
                lines.add(new AthleteBatchLineResult(line, "DUPLICATE", "Atleta já existe", item));
            } else if (validateBatchPositions(item.positions()) != null) {
                lines.add(new AthleteBatchLineResult(line, "INVALID", validateBatchPositions(item.positions()), item));
            } else {
                valid++;
                lines.add(new AthleteBatchLineResult(line, "VALID", null, item));
            }
        }
        return new AthleteBatchResponse(request.athletes().size(), 0, 0, lines);
    }

    /**
     * Cria uma carga em lote. Processa linha a linha: linhas validas sao
     * criadas; duplicadas e invalidas sao reportadas sem abortar as demais.
     */
    @Transactional
    public AthleteBatchResponse createBatch(CreateAthleteBatchRequest request) {
        List<AthleteBatchLineResult> lines = new ArrayList<>();
        int imported = 0;
        for (int i = 0; i < request.athletes().size(); i++) {
            CreateAthleteBatchItem item = request.athletes().get(i);
            int line = i + 2;
            if (item.name() == null || item.name().isBlank()) {
                lines.add(new AthleteBatchLineResult(line, "INVALID", "Informe o nome", item));
            } else if (item.cpf() == null || !DocumentValidator.isValid(item.cpf(), DocumentType.CPF)) {
                lines.add(new AthleteBatchLineResult(line, "INVALID", "CPF inválido", item));
            } else if (repository.existsByCpf(item.cpf().replaceAll("\\D", ""))) {
                lines.add(new AthleteBatchLineResult(line, "DUPLICATE", "CPF já cadastrado", item));
            } else if (repository.existsByNameIgnoreCase(item.name().trim())) {
                lines.add(new AthleteBatchLineResult(line, "DUPLICATE", "Atleta já existe", item));
            } else if (validateBatchPositions(item.positions()) != null) {
                lines.add(new AthleteBatchLineResult(line, "INVALID", validateBatchPositions(item.positions()), item));
            } else {
                CreateAthleteRequest createRequest = new CreateAthleteRequest(
                        item.name().trim(), item.cpf().replaceAll("\\D", ""),
                        item.nickname(), item.positions(), item.number(), item.photoUrl(),
                        null, null);
                AthleteEntity entity = mapper.toEntity(createRequest);
                entity.setStatus(AthleteStatus.ACTIVE);
                repository.save(entity);
                imported++;
                lines.add(new AthleteBatchLineResult(line, "IMPORTED", null, item));
            }
        }
        return new AthleteBatchResponse(
                request.athletes().size(), imported, request.athletes().size() - imported, lines);
    }

    public PagedResponse<AthleteResponse> findAll(int page, int size) {
        Page<AthleteEntity> result = repository.findAll(
                PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "name")));
        return new PagedResponse<>(
                mapper.toResponseList(result.getContent()),
                result.getTotalElements());
    }

    public AthleteResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public AthleteResponse update(UUID id, UpdateAthleteRequest request) {
        AthleteEntity entity = findEntityById(id);
        validateCpf(request.cpf(), id);
        List<AthletePosition> positions = validatePositions(request.positions());
        mapper.updateEntity(entity, request);
        entity.setPositions(positions);
        if (request.birthDate() != null) {
            entity.setBirthDate(request.birthDate());
        }
        if (request.gender() != null) {
            entity.setGender(request.gender());
        }

        return mapper.toResponse(repository.save(entity));
    }

    @Transactional
    public void deactivate(UUID id) {
        AthleteEntity entity = findEntityById(id);
        entity.setStatus(AthleteStatus.INACTIVE);
        repository.save(entity);
    }

    @Transactional
    public void reactivate(UUID id) {
        AthleteEntity entity = findEntityById(id);
        entity.setStatus(AthleteStatus.ACTIVE);
        repository.save(entity);
    }

    private AthleteEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new AthleteNotFoundException(id));
    }

    @Override
    public void assertExists(UUID id) {
        findEntityById(id);
    }

    @Override
    public boolean existsById(UUID id) {
        return repository.existsById(id);
    }

    @Override
    public AthleteInfo findAthleteInfoById(UUID id) {
        AthleteEntity entity = findEntityById(id);
        return new AthleteInfo(
                entity.getId(),
                entity.getName(),
                entity.getNickname(),
                primaryPosition(entity.getPositions()),
                entity.getNumber(),
                entity.getPhotoUrl());
    }

    /**
     * Valida as posições do atleta: até {@value #MAX_POSITIONS} posições e sem
     * duplicatas. {@code null} é tratado como lista vazia.
     */
    private List<AthletePosition> validatePositions(List<AthletePosition> positions) {
        List<AthletePosition> normalized = normalizePositions(positions);
        if (normalized.size() > MAX_POSITIONS) {
            throw new InvalidAthletePositionsException(
                    "O atleta pode ter no máximo %d posições.".formatted(MAX_POSITIONS));
        }
        if (normalized.stream().map(AthletePosition::name).distinct().count() != normalized.size()) {
            throw new InvalidAthletePositionsException("Posições duplicadas não são permitidas.");
        }
        return normalized;
    }

    private List<AthletePosition> normalizePositions(List<AthletePosition> positions) {
        return positions == null ? List.of() : positions;
    }

    /**
     * Valida as posições de uma linha do import em lote (máx. 3, sem
     * duplicatas). Retorna mensagem de erro, ou {@code null} se válido.
     */
    private String validateBatchPositions(List<AthletePosition> positions) {
        List<AthletePosition> normalized = normalizePositions(positions);
        if (normalized.size() > MAX_POSITIONS) {
            return "O atleta pode ter no máximo %d posições.".formatted(MAX_POSITIONS);
        }
        if (normalized.stream().map(AthletePosition::name).distinct().count() != normalized.size()) {
            return "Posições duplicadas não são permitidas.";
        }
        return null;
    }

    private AthletePosition primaryPosition(List<AthletePosition> positions) {
        if (positions == null || positions.isEmpty()) {
            return null;
        }
        return positions.get(0);
    }

    /**
     * Valida o CPF do atleta: obrigatorio, digitos verificadores validos e unico.
     */
    private void validateCpf(String cpf, UUID currentId) {
        if (cpf == null || cpf.isBlank()) {
            throw new InvalidDocumentException("Informe o CPF do atleta.");
        }
        if (!DocumentValidator.isValid(cpf, DocumentType.CPF)) {
            throw new InvalidDocumentException("CPF inválido.");
        }
        String normalized = cpf.replaceAll("\\D", "");
        boolean duplicate = currentId == null
                ? repository.existsByCpf(normalized)
                : repository.existsByCpfAndIdNot(normalized, currentId);
        if (duplicate) {
            throw new DuplicateDocumentException(normalized);
        }
    }

}
