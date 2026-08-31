package br.com.flagplatform.organization.repository;

import br.com.flagplatform.common.enums.OrganizationStatus;
import br.com.flagplatform.common.enums.OrganizationType;
import br.com.flagplatform.organization.entity.OrganizationEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OrganizationRepository extends JpaRepository<OrganizationEntity, UUID> {

    boolean existsByTradeNameIgnoreCase(String tradeName);

    boolean existsByTradeNameIgnoreCaseAndIdNot(String tradeName, UUID id);

    boolean existsByDocument(String document);

    boolean existsByDocumentAndIdNot(String document, UUID id);

    Optional<OrganizationEntity> findByTradeNameIgnoreCase(String tradeName);

    List<OrganizationEntity> findAllByOrderByTradeNameAsc();

    Page<OrganizationEntity> findAllByStatus(OrganizationStatus status, Pageable pageable);

    List<OrganizationEntity> findAllByParentIdAndOrganizationTypeInOrderByTradeNameAsc(
            UUID parentId, Collection<OrganizationType> organizationTypes);

}
