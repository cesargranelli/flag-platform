package br.com.flagplatform.roster.dto.response;

import br.com.flagplatform.roster.dto.request.RosterBatchItem;

public record RosterBatchLineResult(
        Integer line,
        String status,
        String reason,
        RosterBatchItem item
) {
}
