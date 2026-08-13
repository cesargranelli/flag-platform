package br.com.flagplatform.venue.service;

import br.com.flagplatform.organization.OrganizationLookup;
import br.com.flagplatform.venue.dto.request.CreateVenueRequest;
import br.com.flagplatform.venue.dto.request.UpdateVenueRequest;
import br.com.flagplatform.venue.dto.response.VenueResponse;
import br.com.flagplatform.venue.entity.VenueEntity;
import br.com.flagplatform.venue.exception.DuplicateVenueNameException;
import br.com.flagplatform.venue.exception.VenueNotFoundException;
import br.com.flagplatform.venue.mapper.VenueMapper;
import br.com.flagplatform.venue.repository.VenueRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class VenueService {

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

    public List<VenueResponse> findAll() {
        return mapper.toResponseList(repository.findAllByOrderByNameAsc());
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

}
