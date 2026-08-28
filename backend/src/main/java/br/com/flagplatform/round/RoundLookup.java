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

    /**
     * Dada uma lista de roundIds, retorna um mapa roundId → competitionId.
     * Útil para resolver competitionIds em lote sem N+1.
     */
    java.util.Map<UUID, UUID> findCompetitionIdsByRoundIds(java.util.Collection<UUID> roundIds);

    /**
     * Dada uma lista de roundIds, retorna um mapa roundId → RoundInfo.
     * Útil para resolver números de rodada em lote sem N+1.
     */
    java.util.Map<UUID, RoundInfo> findRoundInfoByIds(java.util.Collection<UUID> roundIds);

}
