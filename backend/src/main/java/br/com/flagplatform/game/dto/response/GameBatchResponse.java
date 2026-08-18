package br.com.flagplatform.game.dto.response;

import java.util.List;

public record GameBatchResponse(
        int total,
        int imported,
        int skipped,
        List<GameBatchLineResult> lines
) {
}
