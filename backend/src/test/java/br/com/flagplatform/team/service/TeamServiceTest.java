package br.com.flagplatform.team.service;

import br.com.flagplatform.category.CategoryLookup;
import br.com.flagplatform.category.exception.CategoryNotFoundException;
import br.com.flagplatform.team.dto.request.CreateTeamRequest;
import br.com.flagplatform.team.dto.request.UpdateTeamRequest;
import br.com.flagplatform.team.dto.response.TeamResponse;
import br.com.flagplatform.team.entity.TeamEntity;
import br.com.flagplatform.team.exception.DuplicateTeamNameException;
import br.com.flagplatform.team.exception.TeamNotFoundException;
import br.com.flagplatform.team.mapper.TeamMapper;
import br.com.flagplatform.team.repository.TeamRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

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
class TeamServiceTest {

    @Mock
    private TeamMapper mapper;

    @Mock
    private TeamRepository repository;

    @Mock
    private CategoryLookup categoryLookup;

    @InjectMocks
    private TeamService service;

    @Test
    void create_savesTeamAfterValidatingCategory() {
        UUID categoryId = UUID.randomUUID();
        CreateTeamRequest request = createRequest(categoryId, "Tritões FC");
        TeamEntity entity = entity(categoryId, "Tritões FC");
        TeamResponse expected = response(entity);

        when(repository.existsByCategoryIdAndNameIgnoreCase(categoryId, request.name()))
                .thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        TeamResponse response = service.create(request);

        assertThat(response).isSameAs(expected);
        verify(categoryLookup).assertExists(categoryId);
        verify(repository).save(entity);
    }

    @Test
    void create_throwsWhenNameAlreadyExistsForCategory() {
        UUID categoryId = UUID.randomUUID();
        CreateTeamRequest request = createRequest(categoryId, "Tritões FC");

        when(repository.existsByCategoryIdAndNameIgnoreCase(categoryId, request.name()))
                .thenReturn(true);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(DuplicateTeamNameException.class);

        verify(categoryLookup).assertExists(categoryId);
        verify(repository, never()).save(any());
    }

    @Test
    void create_throwsWhenCategoryDoesNotExist() {
        UUID categoryId = UUID.randomUUID();
        CreateTeamRequest request = createRequest(categoryId, "Tritões FC");

        doThrow(new CategoryNotFoundException(categoryId))
                .when(categoryLookup).assertExists(categoryId);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(CategoryNotFoundException.class);

        verify(repository, never()).existsByCategoryIdAndNameIgnoreCase(any(), any());
        verify(repository, never()).save(any());
    }

    @Test
    void findByCategoryId_returnsTeamsOrderedByName() {
        UUID categoryId = UUID.randomUUID();
        List<TeamEntity> entities = List.of(
                entity(categoryId, "Zeta FC"),
                entity(categoryId, "Alpha FC"));
        List<TeamResponse> expected = entities.stream()
                .map(this::response)
                .toList();

        when(repository.findAllByCategoryIdOrderByNameAsc(categoryId)).thenReturn(entities);
        when(mapper.toResponseList(entities)).thenReturn(expected);

        List<TeamResponse> response = service.findByCategoryId(categoryId);

        assertThat(response).hasSize(2).isSameAs(expected);
    }

    @Test
    void findById_returnsTeamWhenFound() {
        UUID id = UUID.randomUUID();
        TeamEntity entity = entity(UUID.randomUUID(), "Tritões FC");
        TeamResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(mapper.toResponse(entity)).thenReturn(expected);

        TeamResponse response = service.findById(id);

        assertThat(response).isSameAs(expected);
    }

    @Test
    void findById_throwsWhenTeamNotFound() {
        UUID id = UUID.randomUUID();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.findById(id))
                .isInstanceOf(TeamNotFoundException.class);
    }

    @Test
    void update_updatesExistingTeam() {
        UUID id = UUID.randomUUID();
        UUID categoryId = UUID.randomUUID();
        UpdateTeamRequest request = updateRequest(categoryId, "Tritões FC 2");
        TeamEntity entity = entity(categoryId, "Tritões FC");
        TeamResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByCategoryIdAndNameIgnoreCaseAndIdNot(
                categoryId, request.name(), id)).thenReturn(false);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        TeamResponse response = service.update(id, request);

        assertThat(response).isSameAs(expected);
        verify(categoryLookup).assertExists(categoryId);
        verify(mapper).updateEntity(entity, request);
        verify(repository).save(entity);
    }

    @Test
    void update_throwsWhenTeamNotFound() {
        UUID id = UUID.randomUUID();
        UpdateTeamRequest request = updateRequest(UUID.randomUUID(), "Tritões FC 2");

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(TeamNotFoundException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void update_throwsWhenNameUsedByAnotherTeam() {
        UUID id = UUID.randomUUID();
        UUID categoryId = UUID.randomUUID();
        UpdateTeamRequest request = updateRequest(categoryId, "Tritões FC 2");
        TeamEntity entity = entity(categoryId, "Tritões FC");

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByCategoryIdAndNameIgnoreCaseAndIdNot(
                categoryId, request.name(), id)).thenReturn(true);

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(DuplicateTeamNameException.class);

        verify(repository, never()).save(any());
        verify(mapper, never()).updateEntity(eq(entity), any(UpdateTeamRequest.class));
    }

    private CreateTeamRequest createRequest(UUID categoryId, String name) {
        return new CreateTeamRequest(categoryId, name, "TRI", null);
    }

    private UpdateTeamRequest updateRequest(UUID categoryId, String name) {
        return new UpdateTeamRequest(categoryId, name, "TRI", null);
    }

    private TeamEntity entity(UUID categoryId, String name) {
        TeamEntity entity = new TeamEntity();
        entity.setId(UUID.randomUUID());
        entity.setCategoryId(categoryId);
        entity.setName(name);
        entity.setShortName("TRI");
        return entity;
    }

    private TeamResponse response(TeamEntity entity) {
        return new TeamResponse(
                entity.getId(),
                entity.getCategoryId(),
                entity.getName(),
                entity.getShortName(),
                entity.getLogoUrl(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

}
