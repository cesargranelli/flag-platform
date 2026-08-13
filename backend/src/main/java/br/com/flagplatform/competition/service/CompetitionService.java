package br.com.flagplatform.competition.service;

import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.competition.CompetitionLookup;
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

        return mapper.toResponse(repository.save(entity));
    }

    public CompetitionResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    public List<CompetitionResponse> findByOrganizationId(UUID organizationId) {
        return mapper.toResponseList(repository.findAllByOrganizationIdOrderByNameAsc(organizationId));
    }

    public List<CompetitionSummaryResponse> listAllPublic() {
        return repository.findAllByOrderByNameAsc().stream()
                .map(entity -> new CompetitionSummaryResponse(
                        entity.getId(),
                        entity.getName(),
                        organizationLookup.findTradeNameById(entity.getOrganizationId()),
                        entity.getStatus()))
                .toList();
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

        return mapper.toResponse(repository.save(entity));
    }

    @Override
    public void assertExists(UUID id) {
        findEntityById(id);
    }

    private CompetitionEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new CompetitionNotFoundException(id));
    }

}
