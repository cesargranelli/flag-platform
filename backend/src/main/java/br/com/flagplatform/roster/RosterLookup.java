package br.com.flagplatform.roster;

import java.util.List;
import java.util.UUID;

/**
 * API pública do módulo roster para consulta de elencos.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface RosterLookup {

    List<UUID> findAthleteIdsByTeamId(UUID teamId);

}
