package br.com.flagplatform.athlete.repository;

import br.com.flagplatform.athlete.entity.AthleteEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AthleteRepository extends JpaRepository<AthleteEntity, UUID> {

    List<AthleteEntity> findAllByOrderByNameAsc();

    boolean existsByNameIgnoreCase(String name);

    List<AthleteEntity> findByNameIgnoreCase(String name);

    boolean existsByCpf(String cpf);

    boolean existsByCpfAndIdNot(String cpf, UUID id);

}
