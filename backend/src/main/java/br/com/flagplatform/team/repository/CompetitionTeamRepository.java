package br.com.flagplatform.team.repository;

import br.com.flagplatform.team.entity.CompetitionTeamEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CompetitionTeamRepository extends JpaRepository<CompetitionTeamEntity, UUID> {

    List<CompetitionTeamEntity> findAllByCompetitionIdOrderByCreatedAtAsc(UUID competitionId);

    List<CompetitionTeamEntity> findAllByTeamIdOrderByCreatedAtAsc(UUID teamId);

    Optional<CompetitionTeamEntity> findByCompetitionIdAndTeamId(UUID competitionId, UUID teamId);

    boolean existsByCompetitionIdAndTeamId(UUID competitionId, UUID teamId);

}
