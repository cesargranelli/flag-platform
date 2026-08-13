package br.com.flagplatform.game.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record UpdateScoreRequest(
        @NotNull
        @Min(0)
        Integer homeScore,

        @NotNull
        @Min(0)
        Integer awayScore
) {
}
