package br.com.flagplatform.round;

import java.util.List;
import java.util.UUID;

/**
 * API pública do módulo round para consulta de rodadas.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface RoundLookup {

    void assertExists(UUID id);

    UUID findCompetitionId(UUID roundId);

    List<UUID> findRoundIdsByCompetitionId(UUID competitionId);

    List<RoundInfo> findRoundInfoByCompetitionId(UUID competitionId);

    RoundInfo findRoundInfoById(UUID roundId);

}
