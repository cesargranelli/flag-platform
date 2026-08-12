package br.com.flagplatform.category.service;

import br.com.flagplatform.category.dto.request.CreateCategoryRequest;
import br.com.flagplatform.category.dto.request.UpdateCategoryRequest;
import br.com.flagplatform.category.dto.response.CategoryResponse;
import br.com.flagplatform.category.entity.CategoryEntity;
import br.com.flagplatform.category.exception.CategoryNotFoundException;
import br.com.flagplatform.category.exception.DuplicateCategoryNameException;
import br.com.flagplatform.category.mapper.CategoryMapper;
import br.com.flagplatform.category.repository.CategoryRepository;
import br.com.flagplatform.competition.CompetitionLookup;
import br.com.flagplatform.competition.exception.CompetitionNotFoundException;
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
class CategoryServiceTest {

    @Mock
    private CategoryMapper mapper;

    @Mock
    private CategoryRepository repository;

    @Mock
    private CompetitionLookup competitionLookup;

    @InjectMocks
    private CategoryService service;

    @Test
    void create_savesCategoryAfterValidatingCompetition() {
        UUID competitionId = UUID.randomUUID();
        CreateCategoryRequest request = createRequest(competitionId, "Masculino 5x5");
        CategoryEntity entity = entity(competitionId, "Masculino 5x5");
        CategoryResponse expected = response(entity);

        when(repository.existsByCompetitionIdAndNameIgnoreCase(competitionId, request.name()))
                .thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        CategoryResponse response = service.create(request);

        assertThat(response).isSameAs(expected);
        verify(competitionLookup).assertExists(competitionId);
        verify(repository).save(entity);
    }

    @Test
    void create_throwsWhenNameAlreadyExistsForCompetition() {
        UUID competitionId = UUID.randomUUID();
        CreateCategoryRequest request = createRequest(competitionId, "Masculino 5x5");

        when(repository.existsByCompetitionIdAndNameIgnoreCase(competitionId, request.name()))
                .thenReturn(true);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(DuplicateCategoryNameException.class);

        verify(competitionLookup).assertExists(competitionId);
        verify(repository, never()).save(any());
    }

    @Test
    void create_throwsWhenCompetitionDoesNotExist() {
        UUID competitionId = UUID.randomUUID();
        CreateCategoryRequest request = createRequest(competitionId, "Masculino 5x5");

        doThrow(new CompetitionNotFoundException(competitionId))
                .when(competitionLookup).assertExists(competitionId);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(CompetitionNotFoundException.class);

        verify(repository, never()).existsByCompetitionIdAndNameIgnoreCase(any(), any());
        verify(repository, never()).save(any());
    }

    @Test
    void findByCompetitionId_returnsCategoriesOrderedByName() {
        UUID competitionId = UUID.randomUUID();
        List<CategoryEntity> entities = List.of(
                entity(competitionId, "Feminino"),
                entity(competitionId, "Masculino 5x5"));
        List<CategoryResponse> expected = entities.stream()
                .map(this::response)
                .toList();

        when(repository.findAllByCompetitionIdOrderByNameAsc(competitionId)).thenReturn(entities);
        when(mapper.toResponseList(entities)).thenReturn(expected);

        List<CategoryResponse> response = service.findByCompetitionId(competitionId);

        assertThat(response).hasSize(2).isSameAs(expected);
    }

    @Test
    void update_updatesExistingCategory() {
        UUID id = UUID.randomUUID();
        UUID competitionId = UUID.randomUUID();
        UpdateCategoryRequest request = updateRequest(competitionId, "Feminino");
        CategoryEntity entity = entity(competitionId, "Masculino 5x5");
        CategoryResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByCompetitionIdAndNameIgnoreCaseAndIdNot(
                competitionId, request.name(), id)).thenReturn(false);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        CategoryResponse response = service.update(id, request);

        assertThat(response).isSameAs(expected);
        verify(competitionLookup).assertExists(competitionId);
        verify(mapper).updateEntity(entity, request);
        verify(repository).save(entity);
    }

    @Test
    void update_throwsWhenCategoryNotFound() {
        UUID id = UUID.randomUUID();
        UpdateCategoryRequest request = updateRequest(UUID.randomUUID(), "Feminino");

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(CategoryNotFoundException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void update_throwsWhenNameUsedByAnotherCategory() {
        UUID id = UUID.randomUUID();
        UUID competitionId = UUID.randomUUID();
        UpdateCategoryRequest request = updateRequest(competitionId, "Feminino");
        CategoryEntity entity = entity(competitionId, "Masculino 5x5");

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByCompetitionIdAndNameIgnoreCaseAndIdNot(
                competitionId, request.name(), id)).thenReturn(true);

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(DuplicateCategoryNameException.class);

        verify(repository, never()).save(any());
        verify(mapper, never()).updateEntity(eq(entity), any(UpdateCategoryRequest.class));
    }

    @Test
    void delete_deletesExistingCategory() {
        UUID id = UUID.randomUUID();
        CategoryEntity entity = entity(UUID.randomUUID(), "Masculino 5x5");

        when(repository.findById(id)).thenReturn(Optional.of(entity));

        service.delete(id);

        verify(repository).delete(entity);
    }

    @Test
    void delete_throwsWhenCategoryNotFound() {
        UUID id = UUID.randomUUID();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.delete(id))
                .isInstanceOf(CategoryNotFoundException.class);

        verify(repository, never()).delete(any());
    }

    private CreateCategoryRequest createRequest(UUID competitionId, String name) {
        return new CreateCategoryRequest(competitionId, name);
    }

    private UpdateCategoryRequest updateRequest(UUID competitionId, String name) {
        return new UpdateCategoryRequest(competitionId, name);
    }

    private CategoryEntity entity(UUID competitionId, String name) {
        CategoryEntity entity = new CategoryEntity();
        entity.setId(UUID.randomUUID());
        entity.setCompetitionId(competitionId);
        entity.setName(name);
        return entity;
    }

    private CategoryResponse response(CategoryEntity entity) {
        return new CategoryResponse(
                entity.getId(),
                entity.getCompetitionId(),
                entity.getName(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

}
