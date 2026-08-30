package br.com.flagplatform.division.repository;

import br.com.flagplatform.division.entity.DivisionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DivisionRepository extends JpaRepository<DivisionEntity, UUID> {

    List<DivisionEntity> findAllByCompetitionIdOrderByNameAsc(UUID competitionId);

    List<DivisionEntity> findAllByConferenceId(UUID conferenceId);

    boolean existsByCompetitionIdAndConferenceIdAndNameIgnoreCase(
            UUID competitionId, UUID conferenceId, String name);

    boolean existsByCompetitionIdAndConferenceIdAndNameIgnoreCaseAndIdNot(
            UUID competitionId, UUID conferenceId, String name, UUID id);

    boolean existsByCompetitionIdAndConferenceIdIsNullAndNameIgnoreCase(
            UUID competitionId, String name);

    boolean existsByCompetitionIdAndConferenceIdIsNullAndNameIgnoreCaseAndIdNot(
            UUID competitionId, String name, UUID id);

}
