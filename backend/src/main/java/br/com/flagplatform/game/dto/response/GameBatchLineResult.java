package br.com.flagplatform.game.dto.response;

import br.com.flagplatform.game.dto.request.GameBatchItem;

public record GameBatchLineResult(
        Integer line,
        String status,
        String reason,
        GameBatchItem item
) {
}
