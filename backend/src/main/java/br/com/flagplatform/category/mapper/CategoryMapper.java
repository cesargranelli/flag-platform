package br.com.flagplatform.category.mapper;

import br.com.flagplatform.category.dto.request.CreateCategoryRequest;
import br.com.flagplatform.category.dto.request.UpdateCategoryRequest;
import br.com.flagplatform.category.dto.response.CategoryResponse;
import br.com.flagplatform.category.entity.CategoryEntity;
import br.com.flagplatform.common.enums.AgeGroup;
import br.com.flagplatform.common.enums.Gender;
import br.com.flagplatform.modality.ModalityInfo;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring")
public interface CategoryMapper {

    CategoryEntity toEntity(CreateCategoryRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    CategoryEntity updateEntity(
            @MappingTarget CategoryEntity entity,
            UpdateCategoryRequest request);

    default CategoryResponse toResponse(CategoryEntity entity, ModalityInfo modality) {
        return new CategoryResponse(
                entity.getId(),
                entity.getCompetitionId(),
                entity.getModalityId(),
                modality == null ? null : modality.name(),
                modality == null ? null : modality.format(),
                entity.getGender(),
                entity.getAgeGroup(),
                entity.getName(),
                entity.getCreatedAt(),
                entity.getUpdatedAt());
    }

    default List<CategoryResponse> toResponseList(
            List<CategoryEntity> entities, List<ModalityInfo> modalities) {
        return entities.stream()
                .map(entity -> {
                    ModalityInfo modality = modalities.stream()
                            .filter(m -> m.id().equals(entity.getModalityId()))
                            .findFirst()
                            .orElse(null);
                    return toResponse(entity, modality);
                })
                .toList();
    }

    default String deriveName(ModalityInfo modality, Gender gender, AgeGroup ageGroup) {
        if (modality == null) {
            return null;
        }
        return "%s %s · %s · %s".formatted(
                modality.name(),
                modality.format(),
                gender.getDescription(),
                ageGroup.getDescription());
    }

}
