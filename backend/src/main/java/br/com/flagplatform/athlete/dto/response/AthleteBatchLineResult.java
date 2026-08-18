package br.com.flagplatform.athlete.dto.response;

import br.com.flagplatform.athlete.dto.request.CreateAthleteBatchItem;

public record AthleteBatchLineResult(
        Integer line,
        String status,
        String reason,
        CreateAthleteBatchItem item
) {
}
