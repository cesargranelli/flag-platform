package br.com.flagplatform.venue.service;

import br.com.flagplatform.organization.OrganizationLookup;
import br.com.flagplatform.organization.exception.OrganizationNotFoundException;
import br.com.flagplatform.venue.dto.request.CreateVenueRequest;
import br.com.flagplatform.venue.dto.request.UpdateVenueRequest;
import br.com.flagplatform.venue.dto.response.VenueResponse;
import br.com.flagplatform.venue.entity.VenueEntity;
import br.com.flagplatform.venue.exception.DuplicateVenueNameException;
import br.com.flagplatform.venue.exception.VenueNotFoundException;
import br.com.flagplatform.venue.mapper.VenueMapper;
import br.com.flagplatform.venue.repository.VenueRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VenueServiceTest {

    @Mock
    private VenueMapper mapper;

    @Mock
    private VenueRepository repository;

    @Mock
    private OrganizationLookup organizationLookup;

    @InjectMocks
    private VenueService service;

    @Test
    void create_savesVenueAfterValidatingOrganization() {
        UUID organizationId = UUID.randomUUID();
        CreateVenueRequest request = createRequest(organizationId, "Estádio do Morumbi");
        VenueEntity entity = entity(organizationId, "Estádio do Morumbi");
        VenueResponse expected = response(entity);

        when(repository.existsByOrganizationIdAndNameIgnoreCase(organizationId, request.name()))
                .thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        VenueResponse response = service.create(request);

        assertThat(response).isSameAs(expected);
        verify(organizationLookup).assertExists(organizationId);
        verify(repository).save(entity);
    }

    @Test
    void create_throwsWhenNameAlreadyExistsForOrganization() {
        UUID organizationId = UUID.randomUUID();
        CreateVenueRequest request = createRequest(organizationId, "Estádio do Morumbi");

        when(repository.existsByOrganizationIdAndNameIgnoreCase(organizationId, request.name()))
                .thenReturn(true);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(DuplicateVenueNameException.class);

        verify(organizationLookup).assertExists(organizationId);
        verify(repository, never()).save(any());
    }

    @Test
    void create_throwsWhenOrganizationDoesNotExist() {
        UUID organizationId = UUID.randomUUID();
        CreateVenueRequest request = createRequest(organizationId, "Estádio do Morumbi");

        doThrow(new OrganizationNotFoundException(organizationId))
                .when(organizationLookup).assertExists(organizationId);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(OrganizationNotFoundException.class);

        verify(repository, never()).existsByOrganizationIdAndNameIgnoreCase(any(), any());
        verify(repository, never()).save(any());
    }

    @Test
    void findAll_returnsVenuesOrderedByName() {
        List<VenueEntity> entities = List.of(
                entity(UUID.randomUUID(), "Campo B"),
                entity(UUID.randomUUID(), "Campo A"));
        List<VenueResponse> expected = entities.stream()
                .map(this::response)
                .toList();

        when(repository.findAll(any(Pageable.class))).thenReturn(new PageImpl<>(entities));
        when(mapper.toResponseList(entities)).thenReturn(expected);

        var response = service.findAll(0, 10);

        assertThat(response.items()).hasSize(2).isSameAs(expected);
        assertThat(response.total()).isEqualTo(2);
    }

    @Test
    void findById_returnsVenueWhenFound() {
        UUID id = UUID.randomUUID();
        VenueEntity entity = entity(UUID.randomUUID(), "Estádio do Morumbi");
        VenueResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(mapper.toResponse(entity)).thenReturn(expected);

        VenueResponse response = service.findById(id);

        assertThat(response).isSameAs(expected);
    }

    @Test
    void findById_throwsWhenVenueNotFound() {
        UUID id = UUID.randomUUID();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.findById(id))
                .isInstanceOf(VenueNotFoundException.class);
    }

    @Test
    void update_updatesExistingVenue() {
        UUID id = UUID.randomUUID();
        UUID organizationId = UUID.randomUUID();
        UpdateVenueRequest request = updateRequest(organizationId, "Campo 2");
        VenueEntity entity = entity(organizationId, "Campo 1");
        VenueResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByOrganizationIdAndNameIgnoreCaseAndIdNot(
                organizationId, request.name(), id)).thenReturn(false);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        VenueResponse response = service.update(id, request);

        assertThat(response).isSameAs(expected);
        verify(organizationLookup).assertExists(organizationId);
        verify(mapper).updateEntity(entity, request);
        verify(repository).save(entity);
    }

    @Test
    void update_throwsWhenVenueNotFound() {
        UUID id = UUID.randomUUID();
        UpdateVenueRequest request = updateRequest(UUID.randomUUID(), "Campo 2");

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(VenueNotFoundException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void update_throwsWhenNameUsedByAnotherVenue() {
        UUID id = UUID.randomUUID();
        UUID organizationId = UUID.randomUUID();
        UpdateVenueRequest request = updateRequest(organizationId, "Campo 2");
        VenueEntity entity = entity(organizationId, "Campo 1");

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByOrganizationIdAndNameIgnoreCaseAndIdNot(
                organizationId, request.name(), id)).thenReturn(true);

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(DuplicateVenueNameException.class);

        verify(repository, never()).save(any());
        verify(mapper, never()).updateEntity(eq(entity), any(UpdateVenueRequest.class));
    }

    private CreateVenueRequest createRequest(UUID organizationId, String name) {
        return new CreateVenueRequest(organizationId, name, null, null);
    }

    private UpdateVenueRequest updateRequest(UUID organizationId, String name) {
        return new UpdateVenueRequest(organizationId, name, null, null);
    }

    private VenueEntity entity(UUID organizationId, String name) {
        VenueEntity entity = new VenueEntity();
        entity.setId(UUID.randomUUID());
        entity.setOrganizationId(organizationId);
        entity.setName(name);
        return entity;
    }

    private VenueResponse response(VenueEntity entity) {
        return new VenueResponse(
                entity.getId(),
                entity.getOrganizationId(),
                entity.getName(),
                entity.getAddress(),
                entity.getMapsUrl(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

}
