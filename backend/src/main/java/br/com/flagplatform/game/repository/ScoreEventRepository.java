package br.com.flagplatform.game.repository;

import br.com.flagplatform.game.entity.ScoreEventEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ScoreEventRepository extends JpaRepository<ScoreEventEntity, UUID> {

    List<ScoreEventEntity> findAllByGameIdOrderByCreatedAtAsc(UUID gameId);

}
