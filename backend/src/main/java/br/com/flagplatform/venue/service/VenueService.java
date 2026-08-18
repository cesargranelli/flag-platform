package br.com.flagplatform.venue.service;

import br.com.flagplatform.common.pagination.PagedResponse;
import br.com.flagplatform.organization.OrganizationLookup;
import br.com.flagplatform.venue.VenueInfo;
import br.com.flagplatform.venue.VenueLookup;
import br.com.flagplatform.venue.dto.request.CreateVenueRequest;
import br.com.flagplatform.venue.dto.request.UpdateVenueRequest;
import br.com.flagplatform.venue.dto.response.VenueResponse;
import br.com.flagplatform.venue.entity.VenueEntity;
import br.com.flagplatform.venue.exception.DuplicateVenueNameException;
import br.com.flagplatform.venue.exception.VenueNotFoundException;
import br.com.flagplatform.venue.mapper.VenueMapper;
import br.com.flagplatform.venue.repository.VenueRepository;
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
public class VenueService implements VenueLookup {

    private final VenueMapper mapper;
    private final VenueRepository repository;
    private final OrganizationLookup organizationLookup;

    @Transactional
    public VenueResponse create(CreateVenueRequest request) {
        organizationLookup.assertExists(request.organizationId());

        if (repository.existsByOrganizationIdAndNameIgnoreCase(request.organizationId(), request.name())) {
            throw new DuplicateVenueNameException(request.name());
        }

        return mapper.toResponse(repository.save(mapper.toEntity(request)));
    }

    public PagedResponse<VenueResponse> findAll(int page, int size) {
        Page<VenueEntity> result = repository.findAll(
                PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "name")));
        return new PagedResponse<>(
                mapper.toResponseList(result.getContent()),
                result.getTotalElements());
    }

    public VenueResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public VenueResponse update(UUID id, UpdateVenueRequest request) {
        VenueEntity entity = findEntityById(id);
        organizationLookup.assertExists(request.organizationId());

        if (repository.existsByOrganizationIdAndNameIgnoreCaseAndIdNot(
                request.organizationId(), request.name(), id)) {
            throw new DuplicateVenueNameException(request.name());
        }

        mapper.updateEntity(entity, request);

        return mapper.toResponse(repository.save(entity));
    }

    private VenueEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new VenueNotFoundException(id));
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
    public VenueInfo findVenueInfoById(UUID id) {
        VenueEntity entity = findEntityById(id);
        return new VenueInfo(entity.getId(), entity.getName(), entity.getAddress(), entity.getMapsUrl());
    }

}
