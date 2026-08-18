package br.com.flagplatform.category.repository;

import br.com.flagplatform.category.entity.CategoryEntity;
import br.com.flagplatform.common.enums.AgeGroup;
import br.com.flagplatform.common.enums.Gender;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CategoryRepository extends JpaRepository<CategoryEntity, UUID> {

    List<CategoryEntity> findAllByCompetitionIdAndDeletedAtIsNullOrderByNameAsc(UUID competitionId);

    boolean existsByCompetitionIdAndModalityIdAndGenderAndAgeGroupAndDeletedAtIsNull(
            UUID competitionId, UUID modalityId, Gender gender, AgeGroup ageGroup);

    boolean existsByCompetitionIdAndModalityIdAndGenderAndAgeGroupAndDeletedAtIsNullAndIdNot(
            UUID competitionId, UUID modalityId, Gender gender, AgeGroup ageGroup, UUID id);

}
