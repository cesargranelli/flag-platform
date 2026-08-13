package br.com.flagplatform.competition.service;

import br.com.flagplatform.common.enums.CompetitionStatus;
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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CompetitionServiceTest {

    @Mock
    private CompetitionMapper mapper;

    @Mock
    private CompetitionRepository repository;

    @Mock
    private OrganizationLookup organizationLookup;

    @InjectMocks
    private CompetitionService service;

    @Test
    void create_savesCompetitionAsDraftWhenStatusNull() {
        UUID organizationId = UUID.randomUUID();
        CreateCompetitionRequest request = createRequest(organizationId, null);
        CompetitionEntity entity = entity(organizationId, "Taça SP", null);
        CompetitionResponse expected = response(entity);

        when(repository.existsByOrganizationIdAndNameIgnoreCase(organizationId, request.name()))
                .thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        CompetitionResponse response = service.create(request);

        assertThat(response).isSameAs(expected);
        assertThat(entity.getStatus()).isEqualTo(CompetitionStatus.DRAFT);
        verify(organizationLookup).assertExists(organizationId);
        verify(repository).save(entity);
    }

    @Test
    void create_savesCompetitionWithInformedStatus() {
        UUID organizationId = UUID.randomUUID();
        CreateCompetitionRequest request = createRequest(organizationId, CompetitionStatus.PUBLISHED);
        CompetitionEntity entity = entity(organizationId, "Taça SP", CompetitionStatus.PUBLISHED);
        CompetitionResponse expected = response(entity);

        when(repository.existsByOrganizationIdAndNameIgnoreCase(organizationId, request.name()))
                .thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        CompetitionResponse response = service.create(request);

        assertThat(response).isSameAs(expected);
        assertThat(entity.getStatus()).isEqualTo(CompetitionStatus.PUBLISHED);
        verify(organizationLookup).assertExists(organizationId);
        verify(repository).save(entity);
    }

    @Test
    void create_validatesOrganizationExists() {
        UUID organizationId = UUID.randomUUID();
        CreateCompetitionRequest request = createRequest(organizationId, null);
        CompetitionEntity entity = entity(organizationId, "Taça SP", null);
        CompetitionResponse expected = response(entity);

        when(repository.existsByOrganizationIdAndNameIgnoreCase(organizationId, request.name()))
                .thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        service.create(request);

        verify(organizationLookup).assertExists(organizationId);
    }

    @Test
    void create_throwsWhenNameAlreadyExistsForOrganization() {
        UUID organizationId = UUID.randomUUID();
        CreateCompetitionRequest request = createRequest(organizationId, null);

        when(repository.existsByOrganizationIdAndNameIgnoreCase(organizationId, request.name()))
                .thenReturn(true);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(DuplicateCompetitionNameException.class);

        verify(organizationLookup).assertExists(organizationId);
        verify(repository, never()).save(any());
    }

    @Test
    void findById_returnsMappedCompetition() {
        UUID id = UUID.randomUUID();
        CompetitionEntity entity = entity(UUID.randomUUID(), "Taça SP", null);
        CompetitionResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(mapper.toResponse(entity)).thenReturn(expected);

        CompetitionResponse response = service.findById(id);

        assertThat(response).isSameAs(expected);
    }

    @Test
    void findById_throwsWhenCompetitionNotFound() {
        UUID id = UUID.randomUUID();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.findById(id))
                .isInstanceOf(CompetitionNotFoundException.class);
    }

    @Test
    void findByOrganizationId_returnsCompetitionsOrderedByName() {
        UUID organizationId = UUID.randomUUID();
        List<CompetitionEntity> entities = List.of(
                entity(organizationId, "Taça SP", null),
                entity(organizationId, "Copa Paulista", null));
        List<CompetitionResponse> expected = entities.stream()
                .map(this::response)
                .toList();

        when(repository.findAllByOrganizationIdOrderByNameAsc(organizationId)).thenReturn(entities);
        when(mapper.toResponseList(entities)).thenReturn(expected);

        List<CompetitionResponse> response = service.findByOrganizationId(organizationId);

        assertThat(response).hasSize(2).isSameAs(expected);
    }

    @Test
    void listAllPublic_returnsCompetitionsOrderedByNameWithOrganizationName() {
        UUID firstOrgId = UUID.randomUUID();
        UUID secondOrgId = UUID.randomUUID();
        CompetitionEntity copaPaulista = entity(secondOrgId, "Copa Paulista", CompetitionStatus.DRAFT);
        CompetitionEntity tacaSp = entity(firstOrgId, "Taça SP", CompetitionStatus.PUBLISHED);
        List<CompetitionEntity> entities = List.of(copaPaulista, tacaSp);

        when(repository.findAllByOrderByNameAsc()).thenReturn(entities);
        when(organizationLookup.findTradeNameById(firstOrgId)).thenReturn("APFA");
        when(organizationLookup.findTradeNameById(secondOrgId)).thenReturn("Flag SP");

        List<CompetitionSummaryResponse> response = service.listAllPublic();

        assertThat(response).hasSize(2);
        assertThat(response.get(0).id()).isEqualTo(copaPaulista.getId());
        assertThat(response.get(0).name()).isEqualTo("Copa Paulista");
        assertThat(response.get(0).organizationName()).isEqualTo("Flag SP");
        assertThat(response.get(0).status()).isEqualTo(CompetitionStatus.DRAFT);
        assertThat(response.get(1).id()).isEqualTo(tacaSp.getId());
        assertThat(response.get(1).name()).isEqualTo("Taça SP");
        assertThat(response.get(1).organizationName()).isEqualTo("APFA");
        assertThat(response.get(1).status()).isEqualTo(CompetitionStatus.PUBLISHED);
        verify(organizationLookup).findTradeNameById(firstOrgId);
        verify(organizationLookup).findTradeNameById(secondOrgId);
    }

    @Test
    void update_updatesExistingCompetition() {
        UUID id = UUID.randomUUID();
        UUID organizationId = UUID.randomUUID();
        UpdateCompetitionRequest request = updateRequest(organizationId, CompetitionStatus.PUBLISHED);
        CompetitionEntity entity = entity(organizationId, "Taça SP", null);
        CompetitionResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByOrganizationIdAndNameIgnoreCaseAndIdNot(
                organizationId, request.name(), id)).thenReturn(false);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        CompetitionResponse response = service.update(id, request);

        assertThat(response).isSameAs(expected);
        verify(organizationLookup).assertExists(organizationId);
        verify(mapper).updateEntity(entity, request);
        verify(repository).save(entity);
    }

    @Test
    void update_throwsWhenCompetitionNotFound() {
        UUID id = UUID.randomUUID();
        UpdateCompetitionRequest request = updateRequest(UUID.randomUUID(), null);

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(CompetitionNotFoundException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void update_throwsWhenNameUsedByAnotherCompetition() {
        UUID id = UUID.randomUUID();
        UUID organizationId = UUID.randomUUID();
        UpdateCompetitionRequest request = updateRequest(organizationId, null);
        CompetitionEntity entity = entity(organizationId, "Taça SP", null);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByOrganizationIdAndNameIgnoreCaseAndIdNot(
                organizationId, request.name(), id)).thenReturn(true);

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(DuplicateCompetitionNameException.class);

        verify(repository, never()).save(any());
        verify(mapper, never()).updateEntity(eq(entity), any(UpdateCompetitionRequest.class));
    }

    private CreateCompetitionRequest createRequest(UUID organizationId, CompetitionStatus status) {
        return new CreateCompetitionRequest(
                organizationId,
                "Taça SP",
                "Campeonato estadual de flag football",
                LocalDate.of(2026, 1, 15),
                LocalDate.of(2026, 6, 30),
                status
        );
    }

    private UpdateCompetitionRequest updateRequest(UUID organizationId, CompetitionStatus status) {
        return new UpdateCompetitionRequest(
                organizationId,
                "Taça SP 2026",
                "Campeonato estadual atualizado",
                LocalDate.of(2026, 1, 15),
                LocalDate.of(2026, 6, 30),
                status
        );
    }

    private CompetitionEntity entity(UUID organizationId, String name, CompetitionStatus status) {
        CompetitionEntity entity = new CompetitionEntity();
        entity.setId(UUID.randomUUID());
        entity.setOrganizationId(organizationId);
        entity.setName(name);
        entity.setDescription("Campeonato estadual de flag football");
        entity.setStartDate(LocalDate.of(2026, 1, 15));
        entity.setEndDate(LocalDate.of(2026, 6, 30));
        entity.setStatus(status);
        return entity;
    }

    private CompetitionResponse response(CompetitionEntity entity) {
        return new CompetitionResponse(
                entity.getId(),
                entity.getOrganizationId(),
                entity.getName(),
                entity.getDescription(),
                entity.getStartDate(),
                entity.getEndDate(),
                entity.getStatus(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

}
