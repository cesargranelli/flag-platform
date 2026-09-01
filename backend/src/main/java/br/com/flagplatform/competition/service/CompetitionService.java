package br.com.flagplatform.competition.service;

import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.common.enums.GroupingType;
import br.com.flagplatform.competition.CompetitionInfo;
import br.com.flagplatform.competition.CompetitionLookup;
import br.com.flagplatform.common.pagination.PagedResponse;
import br.com.flagplatform.competition.dto.request.CreateCompetitionRequest;
import br.com.flagplatform.competition.dto.request.UpdateCompetitionRequest;
import br.com.flagplatform.competition.dto.response.CompetitionResponse;
import br.com.flagplatform.competition.dto.response.CompetitionSummaryResponse;
import br.com.flagplatform.competition.entity.CompetitionEntity;
import br.com.flagplatform.competition.exception.CompetitionNotFoundException;
import br.com.flagplatform.competition.exception.CompetitionNotEditableException;
import br.com.flagplatform.competition.exception.CompetitionNotFinishableException;
import br.com.flagplatform.competition.exception.CompetitionNotOwnedByCreatorException;
import br.com.flagplatform.competition.exception.DuplicateCompetitionNameException;
import br.com.flagplatform.competition.mapper.CompetitionMapper;
import br.com.flagplatform.competition.repository.CompetitionRepository;
import br.com.flagplatform.competition.CompetitionCreatedEvent;
import br.com.flagplatform.organization.OrganizationLookup;
import br.com.flagplatform.user.UserLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class CompetitionService implements CompetitionLookup {

    private final CompetitionMapper mapper;
    private final CompetitionRepository repository;
    private final OrganizationLookup organizationLookup;
    private final UserLookup userLookup;
    private final ApplicationEventPublisher events;

    @Transactional
    public CompetitionResponse create(CreateCompetitionRequest request, String creatorEmail) {
        organizationLookup.assertExists(request.organizationId());

        if (repository.existsByOrganizationIdAndNameIgnoreCase(request.organizationId(), request.name())) {
            throw new DuplicateCompetitionNameException(request.name());
        }

        CompetitionEntity entity = mapper.toEntity(request);
        if (entity.getStatus() == null) {
            entity.setStatus(CompetitionStatus.DRAFT);
        }
        // Issue #308: rótulo do agrupamento — default DIVISIONS.
        if (entity.getGroupingType() == null) {
            entity.setGroupingType(GroupingType.DIVISIONS);
        }
        // V260: registra quem criou o campeonato — base da regra de
        // edição restrita ao criador (ou ADMIN).
        entity.setCreatedBy(userLookup.findUserIdByEmail(creatorEmail));

        CompetitionEntity saved = repository.save(entity);
        // V258: módulos filhos semeiam conferência/divisão padrão a partir do evento.
        events.publishEvent(new CompetitionCreatedEvent(saved.getId()));

        return toResponse(saved);
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
    public void deactivate(UUID id, String currentUserEmail) {
        assertManagedBy(id, currentUserEmail);

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
    public void finish(UUID id, String currentUserEmail) {
        assertManagedBy(id, currentUserEmail);

        CompetitionEntity entity = findEntityById(id);
        if (entity.getStatus() != CompetitionStatus.PUBLISHED) {
            throw new CompetitionNotFinishableException(entity.getStatus());
        }

        entity.setStatus(CompetitionStatus.FINISHED);
        repository.save(entity);
    }

    @Transactional
    public CompetitionResponse update(UUID id, UpdateCompetitionRequest request, String currentUserEmail) {
        // V260: apenas o criador do campeonato (ou ADMIN) pode editar.
        assertManagedBy(id, currentUserEmail);

        CompetitionEntity entity = findEntityById(id);

        // V250: edição permitida apenas enquanto rascunho — publicado,
        // encerrado ou desativado não volta a ser editável.
        if (entity.getStatus() != CompetitionStatus.DRAFT) {
            throw new CompetitionNotEditableException(entity.getStatus());
        }

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

    @Override
    public void assertManagedBy(UUID competitionId, String currentUserEmail) {
        if (userLookup.isAdminByEmail(currentUserEmail)) {
            return;
        }

        CompetitionEntity entity = findEntityById(competitionId);
        UUID createdBy = entity.getCreatedBy();
        // Legado sem criador conhecido (created_by nulo): restrito ao ADMIN.
        if (createdBy == null || !createdBy.equals(userLookup.findUserIdByEmail(currentUserEmail))) {
            throw new CompetitionNotOwnedByCreatorException();
        }
    }

    @Override
    public void assertEditable(UUID competitionId) {
        CompetitionEntity entity = findEntityById(competitionId);
        if (entity.getStatus() != CompetitionStatus.DRAFT) {
            throw new CompetitionNotEditableException(entity.getStatus());
        }
    }

    @Override
    public CompetitionInfo findCompetitionInfoById(UUID id) {
        CompetitionEntity entity = findEntityById(id);
        return new CompetitionInfo(entity.getId(), entity.getName(), entity.getModality(), entity.getGender());
    }

    @Override
    public Map<UUID, CompetitionInfo> findCompetitionInfoByIds(Collection<UUID> ids) {
        if (ids == null || ids.isEmpty()) {
            return Map.of();
        }
        return repository.findAllById(ids).stream()
                .map(entity -> new CompetitionInfo(entity.getId(), entity.getName(), entity.getModality(), entity.getGender()))
                .collect(Collectors.toMap(CompetitionInfo::id, info -> info));
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
                entity.getAgeGroup(),
                entity.getCreatedBy());
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
                base.groupingType(),
                base.season(),
                base.createdBy(),
                base.createdAt(),
                base.updatedAt());
    }

}
