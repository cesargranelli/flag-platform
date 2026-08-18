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
import br.com.flagplatform.athlete.mapper.AthleteMapper;
import br.com.flagplatform.athlete.repository.AthleteRepository;
import br.com.flagplatform.common.pagination.PagedResponse;
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

    private final AthleteMapper mapper;
    private final AthleteRepository repository;

    @Transactional
    public AthleteResponse create(CreateAthleteRequest request) {
        return mapper.toResponse(repository.save(mapper.toEntity(request)));
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
            } else if (repository.existsByNameIgnoreCase(item.name().trim())) {
                lines.add(new AthleteBatchLineResult(line, "DUPLICATE", "Atleta já existe", item));
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
            } else if (repository.existsByNameIgnoreCase(item.name().trim())) {
                lines.add(new AthleteBatchLineResult(line, "DUPLICATE", "Atleta já existe", item));
            } else {
                CreateAthleteRequest createRequest = new CreateAthleteRequest(
                        item.name().trim(), item.nickname(), item.position(), item.number(), item.photoUrl());
                repository.save(mapper.toEntity(createRequest));
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
        mapper.updateEntity(entity, request);

        return mapper.toResponse(repository.save(entity));
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
                entity.getPosition(),
                entity.getNumber(),
                entity.getPhotoUrl());
    }

}
