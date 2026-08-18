package br.com.flagplatform.athlete.dto.response;

import java.util.List;

public record AthleteBatchResponse(
        int total,
        int imported,
        int skipped,
        List<AthleteBatchLineResult> lines
) {
}
