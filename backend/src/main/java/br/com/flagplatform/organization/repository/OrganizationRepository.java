package br.com.flagplatform.organization.repository;

import br.com.flagplatform.organization.entity.OrganizationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface OrganizationRepository extends JpaRepository<OrganizationEntity, UUID> {

    boolean existsByTradeNameIgnoreCase(String tradeName);

    Optional<OrganizationEntity> findByTradeNameIgnoreCase(String tradeName);

}
