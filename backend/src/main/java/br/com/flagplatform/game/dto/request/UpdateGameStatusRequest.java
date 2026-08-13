package br.com.flagplatform.game.dto.request;

import br.com.flagplatform.common.enums.GameStatus;
import jakarta.validation.constraints.NotNull;

public record UpdateGameStatusRequest(
        @NotNull
        GameStatus status
) {
}
