package br.com.flagplatform.standing.repository;

import br.com.flagplatform.standing.entity.StandingEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface StandingRepository extends JpaRepository<StandingEntity, UUID> {

    List<StandingEntity> findAllByCompetitionId(UUID competitionId);

    /**
     * Bulk delete imediato: um delete derivado faria SELECT + remove, adiando o
     * DELETE para o flush (que roda DEPOIS dos INSERTs do saveAll do recálculo),
     * violando a unique (competition_id, team_id).
     */
    @Modifying
    @Query("delete from StandingEntity s where s.competitionId = :competitionId")
    void deleteAllByCompetitionId(@Param("competitionId") UUID competitionId);

}
