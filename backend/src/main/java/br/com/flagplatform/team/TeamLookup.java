package br.com.flagplatform.team;

import java.util.List;
import java.util.UUID;

/**
 * API pública do módulo team para consulta de times.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface TeamLookup {

    void assertExists(UUID id);

    boolean existsById(UUID id);

    List<UUID> findTeamIdsByCompetitionId(UUID competitionId);

    List<TeamInfo> findTeamInfoByCompetitionId(UUID competitionId);

    TeamInfo findTeamInfoById(UUID id);

    UUID findCompetitionIdByTeamId(UUID teamId);

}
