package br.com.flagplatform.venue;

import java.util.UUID;

/**
 * API pública do módulo venue para consulta de campos de jogo.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface VenueLookup {

    void assertExists(UUID id);

    boolean existsById(UUID id);

    VenueInfo findVenueInfoById(UUID id);

}
