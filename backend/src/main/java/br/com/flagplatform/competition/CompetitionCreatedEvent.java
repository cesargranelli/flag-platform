package br.com.flagplatform.competition;

import java.util.UUID;

/**
 * Disparado quando um campeonato é criado (#258). Módulos filhos
 * (conference, division) semeiam suas estruturas padrão a partir dele.
 */
public record CompetitionCreatedEvent(UUID competitionId) {
}
