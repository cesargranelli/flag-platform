package br.com.flagplatform.team.repository;

import br.com.flagplatform.team.entity.TeamEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface TeamRepository extends JpaRepository<TeamEntity, UUID> {

    List<TeamEntity> findAllByCompetitionIdOrderByNameAsc(UUID competitionId);

    boolean existsByCompetitionIdAndOrganizationId(UUID competitionId, UUID organizationId);

    boolean existsByCompetitionIdAndNameIgnoreCase(UUID competitionId, String name);

    boolean existsByCompetitionIdAndNameIgnoreCaseAndIdNot(UUID competitionId, String name, UUID id);

    boolean existsByDocument(String document);

    boolean existsByDocumentAndIdNot(String document, UUID id);

}
