package br.com.flagplatform.division;

import java.util.List;
import java.util.UUID;

/**
 * API pública do módulo division para consulta de divisões.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface DivisionLookup {

    void assertExists(UUID id);

    UUID findCompetitionId(UUID divisionId);

    List<DivisionInfo> findDivisionInfoByCompetitionId(UUID competitionId);

}
