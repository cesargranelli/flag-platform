package br.com.flagplatform.round.repository;

import br.com.flagplatform.round.entity.RoundEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RoundRepository extends JpaRepository<RoundEntity, UUID> {

    List<RoundEntity> findAllByCategoryIdOrderByNumberAsc(UUID categoryId);

    List<RoundEntity> findAllByCategoryId(UUID categoryId);

    boolean existsByCategoryIdAndNumber(UUID categoryId, Integer number);

    boolean existsByCategoryIdAndNumberAndIdNot(UUID categoryId, Integer number, UUID id);

}
