package br.com.flagplatform.division.repository;

import br.com.flagplatform.division.entity.DivisionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DivisionRepository extends JpaRepository<DivisionEntity, UUID> {

    List<DivisionEntity> findAllByCategoryIdOrderByNameAsc(UUID categoryId);

    boolean existsByCategoryIdAndConferenceIdAndNameIgnoreCase(
            UUID categoryId, UUID conferenceId, String name);

    boolean existsByCategoryIdAndConferenceIdAndNameIgnoreCaseAndIdNot(
            UUID categoryId, UUID conferenceId, String name, UUID id);

    boolean existsByCategoryIdAndConferenceIdIsNullAndNameIgnoreCase(
            UUID categoryId, String name);

    boolean existsByCategoryIdAndConferenceIdIsNullAndNameIgnoreCaseAndIdNot(
            UUID categoryId, String name, UUID id);

}