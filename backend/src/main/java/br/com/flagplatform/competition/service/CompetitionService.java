package br.com.flagplatform.competition.service;

import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.competition.CompetitionLookup;
import br.com.flagplatform.common.pagination.PagedResponse;
import br.com.flagplatform.competition.dto.request.CreateCompetitionRequest;
import br.com.flagplatform.competition.dto.request.UpdateCompetitionRequest;
import br.com.flagplatform.competition.dto.response.CompetitionResponse;
import br.com.flagplatform.competition.dto.response.CompetitionSummaryResponse;
import br.com.flagplatform.competition.entity.CompetitionEntity;
import br.com.flagplatform.competition.exception.CompetitionNotFoundException;
import br.com.flagplatform.competition.exception.DuplicateCompetitionNameException;
import br.com.flagplatform.competition.mapper.CompetitionMapper;
import br.com.flagplatform.competition.repository.CompetitionRepository;
import br.com.flagplatform.organization.OrganizationLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class CompetitionService implements CompetitionLookup {

    private final CompetitionMapper mapper;
    private final CompetitionRepository repository;
    private final OrganizationLookup organizationLookup;

    @Transactional
    public CompetitionResponse create(CreateCompetitionRequest request) {
        organizationLookup.assertExists(request.organizationId());

        if (repository.existsByOrganizationIdAndNameIgnoreCase(request.organizationId(), request.name())) {
            throw new DuplicateCompetitionNameException(request.name());
        }

        CompetitionEntity entity = mapper.toEntity(request);
        if (entity.getStatus() == null) {
            entity.setStatus(CompetitionStatus.DRAFT);
        }

        return toResponse(repository.save(entity));
    }

    public CompetitionResponse findById(UUID id, boolean isAdmin) {
        CompetitionEntity entity = findEntityById(id);
        if (entity.getStatus() == CompetitionStatus.DISABLED && !isAdmin) {
            // Desativado é visível apenas ao ADMIN (V246).
            throw new CompetitionNotFoundException(id);
        }
        return toResponse(entity);
    }

    public List<CompetitionResponse> findByOrganizationId(
            UUID organizationId, boolean includeDisabled, boolean isAdmin) {
        boolean showAll = includeDisabled && isAdmin;
        return repository.findAllByOrganizationIdOrderByNameAsc(organizationId).stream()
                .filter(entity -> showAll || entity.getStatus() != CompetitionStatus.DISABLED)
                .map(this::toResponse)
                .toList();
    }

    public PagedResponse<CompetitionSummaryResponse> listAllPublic(
            int page, int size, boolean includeDisabled, boolean isAdmin) {
        boolean showAll = includeDisabled && isAdmin;

        Page<CompetitionEntity> result = showAll
                ? repository.findAll(
                        PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "name")))
                : repository.findAllByStatusNot(
                        CompetitionStatus.DISABLED,
                        PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "name")));

        return new PagedResponse<>(
                result.getContent().stream()
                        .map(this::toSummary)
                        .toList(),
                result.getTotalElements());
    }

    @Transactional
    public void deactivate(UUID id) {
        CompetitionEntity entity = findEntityById(id);
        entity.setStatus(CompetitionStatus.DISABLED);
        repository.save(entity);
    }

    @Transactional
    public void reactivate(UUID id) {
        CompetitionEntity entity = findEntityById(id);
        entity.setStatus(CompetitionStatus.DRAFT);
        repository.save(entity);
    }

    @Transactional
    public CompetitionResponse update(UUID id, UpdateCompetitionRequest request) {
        CompetitionEntity entity = findEntityById(id);
        organizationLookup.assertExists(request.organizationId());

        if (repository.existsByOrganizationIdAndNameIgnoreCaseAndIdNot(
                request.organizationId(), request.name(), id)) {
            throw new DuplicateCompetitionNameException(request.name());
        }

        mapper.updateEntity(entity, request);

        return toResponse(repository.save(entity));
    }

    @Override
    public void assertExists(UUID id) {
        findEntityById(id);
    }

    private CompetitionEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new CompetitionNotFoundException(id));
    }

    /**
     * Monta a response de resumo resolvendo o nome da organização
     * (trade name) via lookup — isolamento de modulith.
     */
    private CompetitionSummaryResponse toSummary(CompetitionEntity entity) {
        return new CompetitionSummaryResponse(
                entity.getId(),
                entity.getName(),
                organizationLookup.findTradeNameById(entity.getOrganizationId()),
                entity.getStatus(),
                entity.getModality(),
                entity.getGender(),
                entity.getAgeGroup());
    }

    /**
     * Monta a response completa resolvendo o nome da organização
     * (trade name) a partir do lookup — o mapper não tem acesso ao módulo
     * de organizações (isolamento de modulith).
     */
    private CompetitionResponse toResponse(CompetitionEntity entity) {
        CompetitionResponse base = mapper.toResponse(entity);
        return new CompetitionResponse(
                base.id(),
                base.organizationId(),
                organizationLookup.findTradeNameById(entity.getOrganizationId()),
                base.modality(),
                base.gender(),
                base.ageGroup(),
                base.name(),
                base.description(),
                base.startDate(),
                base.endDate(),
                base.status(),
                base.createdAt(),
                base.updatedAt());
    }

}
