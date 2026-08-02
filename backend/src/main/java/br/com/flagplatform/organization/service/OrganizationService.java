package br.com.flagplatform.organization.service;

import br.com.flagplatform.common.enums.OrganizationStatus;
import br.com.flagplatform.organization.dto.request.CreateOrganizationRequest;
import br.com.flagplatform.organization.dto.response.OrganizationCreatedResponse;
import br.com.flagplatform.organization.entity.OrganizationEntity;
import br.com.flagplatform.organization.mapper.OrganizationMapper;
import br.com.flagplatform.organization.repository.OrganizationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
@Transactional
@Service
public class OrganizationService {

    private final OrganizationMapper mapper;
    private final OrganizationRepository repository;

    public OrganizationCreatedResponse create(CreateOrganizationRequest request) {
        OrganizationEntity entity = mapper.toEntity(request);

        entity.setStatus(OrganizationStatus.ACTIVE);

        OrganizationEntity saved = repository.save(entity);

        return mapper.toResponse(saved);
    }

}
