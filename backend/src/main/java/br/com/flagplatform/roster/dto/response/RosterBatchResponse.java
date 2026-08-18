package br.com.flagplatform.roster.dto.response;

import java.util.List;

public record RosterBatchResponse(
        int total,
        int imported,
        int skipped,
        List<RosterBatchLineResult> lines
) {
}
