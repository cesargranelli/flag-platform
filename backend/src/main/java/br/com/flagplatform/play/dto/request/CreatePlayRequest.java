package br.com.flagplatform.play.dto.request;

import br.com.flagplatform.play.entity.PlayType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreatePlayRequest(
        @NotNull
        UUID teamId,

        @NotBlank
        @Size(max = 100)
        String playerName,

        @Size(max = 100)
        String receiverName,

        @NotNull
        PlayType playType,

        String description,

        @Min(0)
        Integer yards,

        @Size(max = 5)
        String quarter,

        @Size(max = 10)
        String time,

        Boolean isFirstDown,

        Boolean isTouchdown,

        Boolean isTurnover
) {
}
