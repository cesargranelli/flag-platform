package br.com.flagplatform.checkin.repository;

import br.com.flagplatform.checkin.entity.CheckInEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CheckInRepository extends JpaRepository<CheckInEntity, UUID> {

    List<CheckInEntity> findAllByGameId(UUID gameId);

    Optional<CheckInEntity> findByGameIdAndAthleteId(UUID gameId, UUID athleteId);

    /**
     * Verifica se outro atleta do mesmo time já usa o numero da partida no jogo.
     */
    boolean existsByGameIdAndTeamIdAndMatchNumberAndAthleteIdNot(
            UUID gameId, UUID teamId, Integer matchNumber, UUID athleteId);

}
