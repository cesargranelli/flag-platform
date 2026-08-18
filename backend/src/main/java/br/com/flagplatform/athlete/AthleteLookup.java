package br.com.flagplatform.athlete;

import java.util.UUID;

/**
 * API pública do módulo athlete para consulta de atletas.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface AthleteLookup {

    void assertExists(UUID id);

    boolean existsById(UUID id);

    AthleteInfo findAthleteInfoById(UUID id);

}
