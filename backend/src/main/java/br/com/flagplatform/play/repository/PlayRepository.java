package br.com.flagplatform.play.repository;

import br.com.flagplatform.play.entity.PlayEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PlayRepository extends JpaRepository<PlayEntity, UUID> {

    List<PlayEntity> findByGameIdOrderByCreatedAtDesc(UUID gameId);

    boolean existsByGameId(UUID gameId);

}
