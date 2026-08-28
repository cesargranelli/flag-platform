package br.com.flagplatform.play;

import java.util.UUID;

/**
 * API pública do módulo play para consulta de lances.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface PlayLookup {

    boolean existsByGameId(UUID gameId);

}
