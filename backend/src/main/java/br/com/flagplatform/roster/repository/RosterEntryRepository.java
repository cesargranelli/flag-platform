package br.com.flagplatform.roster.repository;

import br.com.flagplatform.roster.entity.RosterEntryEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RosterEntryRepository extends JpaRepository<RosterEntryEntity, UUID> {

    List<RosterEntryEntity> findAllByRosterIdOrderByCreatedAtAsc(UUID rosterId);

    boolean existsByRosterIdAndAthleteId(UUID rosterId, UUID athleteId);

    Optional<RosterEntryEntity> findByRosterIdAndAthleteId(UUID rosterId, UUID athleteId);

}
