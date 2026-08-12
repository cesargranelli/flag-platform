package br.com.flagplatform.competition;

import java.util.UUID;

/**
 * API pública do módulo competition para consulta de campeonatos.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface CompetitionLookup {

    void assertExists(UUID id);

}
