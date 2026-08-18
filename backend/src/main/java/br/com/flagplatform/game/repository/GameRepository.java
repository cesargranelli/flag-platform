package br.com.flagplatform.game.repository;

import br.com.flagplatform.common.enums.GameStatus;
import br.com.flagplatform.game.entity.GameEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface GameRepository extends JpaRepository<GameEntity, UUID> {

    List<GameEntity> findAllByRoundIdOrderByScheduledAtAsc(UUID roundId);

    List<GameEntity> findAllByRoundIdInOrderByScheduledAtAsc(List<UUID> roundIds);

    List<GameEntity> findAllByRoundIdInAndStatus(List<UUID> roundIds, GameStatus status);

    boolean existsByRoundIdAndHomeTeamIdAndAwayTeamId(
            UUID roundId, UUID homeTeamId, UUID awayTeamId);

}
