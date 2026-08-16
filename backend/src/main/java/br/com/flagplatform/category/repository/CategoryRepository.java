package br.com.flagplatform.category.repository;

import br.com.flagplatform.category.entity.CategoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CategoryRepository extends JpaRepository<CategoryEntity, UUID> {

    List<CategoryEntity> findAllByCompetitionIdAndDeletedAtIsNullOrderByNameAsc(UUID competitionId);

    boolean existsByCompetitionIdAndNameIgnoreCaseAndDeletedAtIsNull(UUID competitionId, String name);

    boolean existsByCompetitionIdAndNameIgnoreCaseAndDeletedAtIsNullAndIdNot(
            UUID competitionId, String name, UUID id);

}
