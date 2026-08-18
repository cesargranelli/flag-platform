package br.com.flagplatform.modality.repository;

import br.com.flagplatform.modality.entity.ModalityEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ModalityRepository extends JpaRepository<ModalityEntity, UUID> {

    List<ModalityEntity> findAllByActiveTrueOrderByFormatAsc();

}
