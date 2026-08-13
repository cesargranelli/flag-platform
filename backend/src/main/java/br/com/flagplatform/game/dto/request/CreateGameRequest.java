package br.com.flagplatform.game.dto.request;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;
import java.util.UUID;

public record CreateGameRequest(
        @NotNull
        UUID roundId,

        @NotNull
        UUID homeTeamId,

        @NotNull
        UUID awayTeamId,

        UUID venueId,

        @NotNull
        LocalDateTime scheduledAt
) {
}
