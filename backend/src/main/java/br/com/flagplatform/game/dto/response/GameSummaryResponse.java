package br.com.flagplatform.game.dto.response;

import br.com.flagplatform.common.enums.GameStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record GameSummaryResponse(
        UUID id,
        UUID roundId,
        Integer roundNumber,
        String homeTeamName,
        String awayTeamName,
        UUID venueId,
        String venueName,
        LocalDateTime scheduledAt,
        GameStatus status,
        Integer homeScore,
        Integer awayScore
) {
}
