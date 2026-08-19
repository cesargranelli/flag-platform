package br.com.flagplatform.organization.repository;

import br.com.flagplatform.organization.entity.OrganizationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OrganizationRepository extends JpaRepository<OrganizationEntity, UUID> {

    boolean existsByTradeNameIgnoreCase(String tradeName);

    boolean existsByTradeNameIgnoreCaseAndIdNot(String tradeName, UUID id);

    boolean existsByDocument(String document);

    boolean existsByDocumentAndIdNot(String document, UUID id);

    boolean existsByPresidentCpf(String presidentCpf);

    boolean existsByPresidentCpfAndIdNot(String presidentCpf, UUID id);

    Optional<OrganizationEntity> findByTradeNameIgnoreCase(String tradeName);

    List<OrganizationEntity> findAllByOrderByTradeNameAsc();

}
