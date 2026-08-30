package br.com.flagplatform.game.repository;

import br.com.flagplatform.common.enums.GameStatus;
import br.com.flagplatform.game.entity.GameEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface GameRepository extends JpaRepository<GameEntity, UUID> {

    List<GameEntity> findAllByRoundIdOrderByScheduledAtAsc(UUID roundId);

    List<GameEntity> findAllByRoundIdInOrderByScheduledAtAsc(List<UUID> roundIds);

    List<GameEntity> findAllByRoundIdInAndStatus(List<UUID> roundIds, GameStatus status);

    boolean existsByRoundIdAndHomeTeamIdAndAwayTeamId(
            UUID roundId, UUID homeTeamId, UUID awayTeamId);

    @Query("""
            SELECT g FROM GameEntity g
            WHERE g.status IN :statuses
              AND g.scheduledAt BETWEEN :start AND :end
            ORDER BY
              CASE WHEN g.status = br.com.flagplatform.common.enums.GameStatus.IN_PROGRESS THEN 0 ELSE 1 END,
              g.scheduledAt DESC
            """)
    List<GameEntity> findLiveGames(
            @Param("statuses") List<GameStatus> statuses,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

}
