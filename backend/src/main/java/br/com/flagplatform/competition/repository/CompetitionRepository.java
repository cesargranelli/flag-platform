package br.com.flagplatform.competition.repository;

import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.competition.entity.CompetitionEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CompetitionRepository extends JpaRepository<CompetitionEntity, UUID> {

    List<CompetitionEntity> findAllByOrganizationIdOrderByNameAsc(UUID organizationId);

    List<CompetitionEntity> findAllByOrderByNameAsc();

    Page<CompetitionEntity> findAllByStatusNot(CompetitionStatus status, Pageable pageable);

    boolean existsByOrganizationIdAndNameIgnoreCase(UUID organizationId, String name);

    boolean existsByOrganizationIdAndNameIgnoreCaseAndIdNot(UUID organizationId, String name, UUID id);

}
