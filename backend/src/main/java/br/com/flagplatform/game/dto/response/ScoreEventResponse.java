package br.com.flagplatform.game.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record ScoreEventResponse(
        UUID id,
        UUID gameId,
        UUID teamId,
        LocalDateTime createdAt
) {
}
