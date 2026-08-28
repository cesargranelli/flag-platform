package br.com.flagplatform.game.dto.response;

import br.com.flagplatform.common.enums.GameStatus;
import br.com.flagplatform.common.enums.Gender;
import br.com.flagplatform.common.enums.Modality;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Resposta enriquecida para o endpoint de jogos ao vivo.
 * Inclui metadados da competição (modalidade, gênero) para que o frontend
 * possa exibir jogos cross-competition sem chamadas adicionais.
 */
public record LiveGameResponse(
        UUID id,
        UUID roundId,
        Integer roundNumber,
        String homeTeamName,
        String awayTeamName,
        UUID venueId,
        String venueName,
        String venueAddress,
        String venueMapsUrl,
        LocalDateTime scheduledAt,
        GameStatus status,
        Integer homeScore,
        Integer awayScore,
        UUID competitionId,
        String competitionName,
        Modality modality,
        Gender gender
) {
}
