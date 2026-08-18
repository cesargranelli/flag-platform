package br.com.flagplatform.game.dto.request;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record GameBatchRequest(
        @NotEmpty
        List<GameBatchItem> games
) {
}
