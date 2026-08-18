package br.com.flagplatform.category.service;

import br.com.flagplatform.category.CategoryLookup;
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
import br.com.flagplatform.modality.ModalityInfo;
import br.com.flagplatform.modality.ModalityLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class CategoryService implements CategoryLookup {

    private final CategoryMapper mapper;
    private final CategoryRepository repository;
    private final CompetitionLookup competitionLookup;
    private final ModalityLookup modalityLookup;

    @Transactional
    public CategoryResponse create(CreateCategoryRequest request) {
        competitionLookup.assertExists(request.competitionId());
        ModalityInfo modality = modalityLookup.findModalityInfoById(request.modalityId());

        ensureUniqueCombination(request.competitionId(), request.modalityId(),
                request.gender(), request.ageGroup(), null);

        CategoryEntity entity = mapper.toEntity(request);
        if (entity.getName() == null || entity.getName().isBlank()) {
            entity.setName(mapper.deriveName(modality, request.gender(), request.ageGroup()));
        }

        return toResponse(repository.save(entity), modality);
    }

    public List<CategoryResponse> findByCompetitionId(UUID competitionId) {
        List<CategoryEntity> entities =
                repository.findAllByCompetitionIdAndDeletedAtIsNullOrderByNameAsc(competitionId);
        return toResponseList(entities);
    }

    public CategoryResponse findById(UUID id) {
        CategoryEntity entity = findEntityById(id);
        return toResponse(entity, modalityLookup.findModalityInfoById(entity.getModalityId()));
    }

    @Transactional
    public CategoryResponse update(UUID id, UpdateCategoryRequest request) {
        CategoryEntity entity = findEntityById(id);
        competitionLookup.assertExists(request.competitionId());
        ModalityInfo modality = modalityLookup.findModalityInfoById(request.modalityId());

        ensureUniqueCombination(request.competitionId(), request.modalityId(),
                request.gender(), request.ageGroup(), id);

        mapper.updateEntity(entity, request);
        if (entity.getName() == null || entity.getName().isBlank()) {
            entity.setName(mapper.deriveName(modality, request.gender(), request.ageGroup()));
        }

        return toResponse(repository.save(entity), modality);
    }

    @Transactional
    public void delete(UUID id) {
        CategoryEntity entity = findEntityById(id);
        entity.setDeletedAt(LocalDateTime.now());
        repository.save(entity);
    }

    @Override
    public void assertExists(UUID id) {
        findEntityById(id);
    }

    @Override
    public List<UUID> findCategoryIdsByCompetitionId(UUID competitionId) {
        return repository.findAllByCompetitionIdAndDeletedAtIsNullOrderByNameAsc(competitionId).stream()
                .map(CategoryEntity::getId)
                .toList();
    }

    private void ensureUniqueCombination(UUID competitionId, UUID modalityId,
                                         Gender gender, AgeGroup ageGroup, UUID currentId) {
        boolean duplicate = currentId == null
                ? repository.existsByCompetitionIdAndModalityIdAndGenderAndAgeGroupAndDeletedAtIsNull(
                        competitionId, modalityId, gender, ageGroup)
                : repository.existsByCompetitionIdAndModalityIdAndGenderAndAgeGroupAndDeletedAtIsNullAndIdNot(
                        competitionId, modalityId, gender, ageGroup, currentId);
        if (duplicate) {
            throw new DuplicateCategoryNameException(
                    "%s %s · %s · %s".formatted(
                            modalityLookup.findModalityInfoById(modalityId).name(),
                            modalityLookup.findModalityInfoById(modalityId).format(),
                            gender.getDescription(),
                            ageGroup.getDescription()));
        }
    }

    private CategoryEntity findEntityById(UUID id) {
        CategoryEntity entity = repository.findById(id)
                .orElseThrow(() -> new CategoryNotFoundException(id));
        if (!entity.isActive()) {
            throw new CategoryNotFoundException(id);
        }
        return entity;
    }

    private CategoryResponse toResponse(CategoryEntity entity, ModalityInfo modality) {
        return mapper.toResponse(entity, modality);
    }

    private List<CategoryResponse> toResponseList(List<CategoryEntity> entities) {
        Map<UUID, ModalityInfo> byId = modalityLookup.listModalityInfo().stream()
                .collect(Collectors.toMap(ModalityInfo::id, Function.identity()));
        return entities.stream()
                .map(entity -> mapper.toResponse(entity, byId.get(entity.getModalityId())))
                .toList();
    }

}
