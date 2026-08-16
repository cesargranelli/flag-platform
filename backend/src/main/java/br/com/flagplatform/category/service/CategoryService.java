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
import br.com.flagplatform.competition.CompetitionLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class CategoryService implements CategoryLookup {

    private final CategoryMapper mapper;
    private final CategoryRepository repository;
    private final CompetitionLookup competitionLookup;

    @Transactional
    public CategoryResponse create(CreateCategoryRequest request) {
        competitionLookup.assertExists(request.competitionId());

        if (repository.existsByCompetitionIdAndNameIgnoreCaseAndDeletedAtIsNull(
                request.competitionId(), request.name())) {
            throw new DuplicateCategoryNameException(request.name());
        }

        return mapper.toResponse(repository.save(mapper.toEntity(request)));
    }

    public List<CategoryResponse> findByCompetitionId(UUID competitionId) {
        return mapper.toResponseList(
                repository.findAllByCompetitionIdAndDeletedAtIsNullOrderByNameAsc(competitionId));
    }

    public CategoryResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public CategoryResponse update(UUID id, UpdateCategoryRequest request) {
        CategoryEntity entity = findEntityById(id);
        competitionLookup.assertExists(request.competitionId());

        if (repository.existsByCompetitionIdAndNameIgnoreCaseAndDeletedAtIsNullAndIdNot(
                request.competitionId(), request.name(), id)) {
            throw new DuplicateCategoryNameException(request.name());
        }

        mapper.updateEntity(entity, request);

        return mapper.toResponse(repository.save(entity));
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

    private CategoryEntity findEntityById(UUID id) {
        CategoryEntity entity = repository.findById(id)
                .orElseThrow(() -> new CategoryNotFoundException(id));
        if (!entity.isActive()) {
            throw new CategoryNotFoundException(id);
        }
        return entity;
    }

}
