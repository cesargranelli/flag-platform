package br.com.flagplatform.conference.repository;

import br.com.flagplatform.conference.entity.ConferenceEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ConferenceRepository extends JpaRepository<ConferenceEntity, UUID> {

    List<ConferenceEntity> findAllByCompetitionIdOrderByNameAsc(UUID competitionId);

    boolean existsByCompetitionIdAndNameIgnoreCase(UUID competitionId, String name);

    boolean existsByCompetitionIdAndNameIgnoreCaseAndIdNot(UUID competitionId, String name, UUID id);

}
