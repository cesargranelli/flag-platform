package br.com.flagplatform.category.service;

import br.com.flagplatform.category.dto.request.CreateCategoryRequest;
import br.com.flagplatform.category.dto.request.UpdateCategoryRequest;
import br.com.flagplatform.category.dto.response.CategoryResponse;
import br.com.flagplatform.category.entity.CategoryEntity;
import br.com.flagplatform.category.exception.CategoryNotFoundException;
import br.com.flagplatform.category.exception.DuplicateCategoryNameException;
import br.com.flagplatform.category.mapper.CategoryMapper;
import br.com.flagplatform.category.repository.CategoryRepository;
import br.com.flagplatform.common.enums.AgeGroup;
import br.com.flagplatform.common.enums.Gender;
import br.com.flagplatform.competition.CompetitionLookup;
import br.com.flagplatform.competition.exception.CompetitionNotFoundException;
import br.com.flagplatform.modality.ModalityInfo;
import br.com.flagplatform.modality.ModalityLookup;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
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

    private static final UUID MODALITY_ID = UUID.randomUUID();
    private static final Gender GENDER = Gender.MALE;
    private static final AgeGroup AGE_GROUP = AgeGroup.ADULT;
    private static final ModalityInfo MODALITY = new ModalityInfo(MODALITY_ID, "Flag Football", "5x5");

    @Mock
    private CategoryMapper mapper;

    @Mock
    private CategoryRepository repository;

    @Mock
    private CompetitionLookup competitionLookup;

    @Mock
    private ModalityLookup modalityLookup;

    @InjectMocks
    private CategoryService service;

    @Test
    void create_savesCategoryAfterValidatingCompetition() {
        UUID competitionId = UUID.randomUUID();
        CreateCategoryRequest request = createRequest(competitionId, "Masculino 5x5");
        CategoryEntity entity = entity(competitionId, "Masculino 5x5");
        CategoryResponse expected = response(entity);

        when(modalityLookup.findModalityInfoById(MODALITY_ID)).thenReturn(MODALITY);
        when(repository.existsByCompetitionIdAndModalityIdAndGenderAndAgeGroupAndDeletedAtIsNull(
                        competitionId, MODALITY_ID, GENDER, AGE_GROUP))
                .thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity, MODALITY)).thenReturn(expected);

        CategoryResponse response = service.create(request);

        assertThat(response).isSameAs(expected);
        verify(competitionLookup).assertExists(competitionId);
        verify(repository).save(entity);
    }

    @Test
    void create_derivesNameWhenBlank() {
        UUID competitionId = UUID.randomUUID();
        CreateCategoryRequest request = createRequest(competitionId, null);
        CategoryEntity entity = entity(competitionId, null);

        when(modalityLookup.findModalityInfoById(MODALITY_ID)).thenReturn(MODALITY);
        when(repository.existsByCompetitionIdAndModalityIdAndGenderAndAgeGroupAndDeletedAtIsNull(
                        competitionId, MODALITY_ID, GENDER, AGE_GROUP))
                .thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(mapper.deriveName(MODALITY, GENDER, AGE_GROUP))
                .thenReturn("Flag Football 5x5 · Masculino · Adulto");
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity, MODALITY)).thenReturn(response(entity));

        service.create(request);

        assertThat(entity.getName()).isEqualTo("Flag Football 5x5 · Masculino · Adulto");
        verify(mapper).deriveName(MODALITY, GENDER, AGE_GROUP);
    }

    @Test
    void create_throwsWhenCombinationAlreadyExistsForCompetition() {
        UUID competitionId = UUID.randomUUID();
        CreateCategoryRequest request = createRequest(competitionId, "Masculino 5x5");

        when(modalityLookup.findModalityInfoById(MODALITY_ID)).thenReturn(MODALITY);
        when(repository.existsByCompetitionIdAndModalityIdAndGenderAndAgeGroupAndDeletedAtIsNull(
                        competitionId, MODALITY_ID, GENDER, AGE_GROUP))
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

        verify(repository, never()).save(any());
    }

    @Test
    void findByCompetitionId_returnsCategoriesOrderedByName() {
        UUID competitionId = UUID.randomUUID();
        List<CategoryEntity> entities = List.of(
                entity(competitionId, "Feminino"),
                entity(competitionId, "Masculino 5x5"));

        when(repository.findAllByCompetitionIdAndDeletedAtIsNullOrderByNameAsc(competitionId))
                .thenReturn(entities);
        when(modalityLookup.listModalityInfo()).thenReturn(List.of(MODALITY));
        when(mapper.toResponse(entities.get(0), MODALITY)).thenReturn(response(entities.get(0)));
        when(mapper.toResponse(entities.get(1), MODALITY)).thenReturn(response(entities.get(1)));

        List<CategoryResponse> response = service.findByCompetitionId(competitionId);

        assertThat(response).hasSize(2)
                .extracting(CategoryResponse::name)
                .containsExactly("Feminino", "Masculino 5x5");
    }

    @Test
    void update_updatesExistingCategory() {
        UUID id = UUID.randomUUID();
        UUID competitionId = UUID.randomUUID();
        UpdateCategoryRequest request = updateRequest(competitionId, "Feminino");
        CategoryEntity entity = entity(competitionId, "Masculino 5x5");
        CategoryResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(modalityLookup.findModalityInfoById(MODALITY_ID)).thenReturn(MODALITY);
        when(repository.existsByCompetitionIdAndModalityIdAndGenderAndAgeGroupAndDeletedAtIsNullAndIdNot(
                        competitionId, MODALITY_ID, GENDER, AGE_GROUP, id)).thenReturn(false);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity, MODALITY)).thenReturn(expected);

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
    void update_throwsWhenCombinationUsedByAnotherCategory() {
        UUID id = UUID.randomUUID();
        UUID competitionId = UUID.randomUUID();
        UpdateCategoryRequest request = updateRequest(competitionId, "Feminino");
        CategoryEntity entity = entity(competitionId, "Masculino 5x5");

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(modalityLookup.findModalityInfoById(MODALITY_ID)).thenReturn(MODALITY);
        when(repository.existsByCompetitionIdAndModalityIdAndGenderAndAgeGroupAndDeletedAtIsNullAndIdNot(
                        competitionId, MODALITY_ID, GENDER, AGE_GROUP, id)).thenReturn(true);

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(DuplicateCategoryNameException.class);

        verify(repository, never()).save(any());
        verify(mapper, never()).updateEntity(eq(entity), any(UpdateCategoryRequest.class));
    }

    @Test
    void delete_softDeletesCategory() {
        UUID id = UUID.randomUUID();
        CategoryEntity entity = entity(UUID.randomUUID(), "Masculino 5x5");

        when(repository.findById(id)).thenReturn(Optional.of(entity));

        service.delete(id);

        assertThat(entity.getDeletedAt()).isNotNull();
        verify(repository).save(entity);
        verify(repository, never()).delete(any());
    }

    @Test
    void delete_throwsWhenCategoryNotFound() {
        UUID id = UUID.randomUUID();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.delete(id))
                .isInstanceOf(CategoryNotFoundException.class);

        verify(repository, never()).delete(any());
    }

    @Test
    void findById_returnsCategory() {
        UUID id = UUID.randomUUID();
        UUID competitionId = UUID.randomUUID();
        CategoryEntity entity = entity(competitionId, "Masculino 5x5");
        CategoryResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(modalityLookup.findModalityInfoById(MODALITY_ID)).thenReturn(MODALITY);
        when(mapper.toResponse(entity, MODALITY)).thenReturn(expected);

        CategoryResponse response = service.findById(id);

        assertThat(response).isSameAs(expected);
    }

    @Test
    void findById_throwsWhenCategoryNotFound() {
        UUID id = UUID.randomUUID();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.findById(id))
                .isInstanceOf(CategoryNotFoundException.class);
    }

    @Test
    void findById_throwsWhenCategorySoftDeleted() {
        UUID id = UUID.randomUUID();
        CategoryEntity entity = entity(UUID.randomUUID(), "Masculino 5x5");
        entity.setDeletedAt(LocalDateTime.now());

        when(repository.findById(id)).thenReturn(Optional.of(entity));

        assertThatThrownBy(() -> service.findById(id))
                .isInstanceOf(CategoryNotFoundException.class);
    }

    private CreateCategoryRequest createRequest(UUID competitionId, String name) {
        return new CreateCategoryRequest(competitionId, MODALITY_ID, GENDER, AGE_GROUP, name);
    }

    private UpdateCategoryRequest updateRequest(UUID competitionId, String name) {
        return new UpdateCategoryRequest(competitionId, MODALITY_ID, GENDER, AGE_GROUP, name);
    }

    private CategoryEntity entity(UUID competitionId, String name) {
        CategoryEntity entity = new CategoryEntity();
        entity.setId(UUID.randomUUID());
        entity.setCompetitionId(competitionId);
        entity.setModalityId(MODALITY_ID);
        entity.setGender(GENDER);
        entity.setAgeGroup(AGE_GROUP);
        entity.setName(name);
        return entity;
    }

    private CategoryResponse response(CategoryEntity entity) {
        return new CategoryResponse(
                entity.getId(),
                entity.getCompetitionId(),
                MODALITY_ID,
                MODALITY.name(),
                MODALITY.format(),
                entity.getGender(),
                entity.getAgeGroup(),
                entity.getName(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

}
