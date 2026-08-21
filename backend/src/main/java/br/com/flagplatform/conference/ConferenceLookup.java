package br.com.flagplatform.conference;

import java.util.List;
import java.util.UUID;

/**
 * API pública do módulo conference para consulta de conferências.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface ConferenceLookup {

    void assertExists(UUID id);

    UUID findCompetitionId(UUID conferenceId);

    List<ConferenceInfo> findConferenceInfoByCompetitionId(UUID competitionId);

}
