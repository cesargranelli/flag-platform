package br.com.flagplatform.round.dto.request;

import br.com.flagplatform.common.enums.RoundType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record UpdateRoundRequest(
        @NotNull
        UUID competitionId,

        @NotNull
        Integer number,

        @NotBlank
        @Size(max = 100)
        String name,

        @NotNull
        RoundType type
) {
}
