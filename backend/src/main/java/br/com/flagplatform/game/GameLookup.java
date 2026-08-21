package br.com.flagplatform.game;

import java.util.List;
import java.util.UUID;

/**
 * API pública do módulo game para consulta de jogos finalizados.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface GameLookup {

    List<FinishedGame> findFinishedByCompetitionId(UUID competitionId);

    GameInfo findGameInfoById(UUID id);

}
