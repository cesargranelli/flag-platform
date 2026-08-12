package br.com.flagplatform.organization.service;

import br.com.flagplatform.common.enums.OrganizationStatus;
import br.com.flagplatform.organization.OrganizationLookup;
import br.com.flagplatform.organization.dto.request.CreateOrganizationRequest;
import br.com.flagplatform.organization.dto.request.UpdateOrganizationRequest;
import br.com.flagplatform.organization.dto.response.OrganizationCreatedResponse;
import br.com.flagplatform.organization.dto.response.OrganizationResponse;
import br.com.flagplatform.organization.entity.OrganizationEntity;
import br.com.flagplatform.organization.exception.DuplicateTradeNameException;
import br.com.flagplatform.organization.exception.OrganizationNotFoundException;
import br.com.flagplatform.organization.mapper.OrganizationMapper;
import br.com.flagplatform.organization.repository.OrganizationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class OrganizationService implements OrganizationLookup {

    private final OrganizationMapper mapper;
    private final OrganizationRepository repository;

    @Transactional
    public OrganizationCreatedResponse create(CreateOrganizationRequest request) {

        if (repository.existsByTradeNameIgnoreCase(request.tradeName())) {
            throw new DuplicateTradeNameException(request.tradeName());
        }

        OrganizationEntity entity = mapper.toEntity(request);
        entity.setStatus(OrganizationStatus.ACTIVE);

        OrganizationEntity saved = repository.save(entity);

        return mapper.toResponse(saved);
    }

    public List<OrganizationResponse> findAll() {
        return mapper.toDetailResponseList(repository.findAllByOrderByTradeNameAsc());
    }

    public OrganizationResponse findById(UUID id) {
        return mapper.toDetailResponse(findEntityById(id));
    }

    @Transactional
    public OrganizationResponse update(UUID id, UpdateOrganizationRequest request) {

        OrganizationEntity entity = findEntityById(id);

        if (repository.existsByTradeNameIgnoreCaseAndIdNot(request.tradeName(), id)) {
            throw new DuplicateTradeNameException(request.tradeName());
        }

        mapper.updateEntity(entity, request);

        return mapper.toDetailResponse(repository.save(entity));
    }

    @Override
    public void assertExists(UUID id) {
        findEntityById(id);
    }

    private OrganizationEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new OrganizationNotFoundException(id));
    }

}
