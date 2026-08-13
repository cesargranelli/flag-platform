package br.com.flagplatform.game.dto.response;

import br.com.flagplatform.common.enums.GameStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record GameResponse(
        UUID id,
        UUID roundId,
        UUID homeTeamId,
        UUID awayTeamId,
        UUID venueId,
        LocalDateTime scheduledAt,
        GameStatus status,
        Integer homeScore,
        Integer awayScore,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
