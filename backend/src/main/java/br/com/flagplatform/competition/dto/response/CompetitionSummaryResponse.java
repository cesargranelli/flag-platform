package br.com.flagplatform.competition.dto.response;

import br.com.flagplatform.common.enums.CompetitionStatus;

import java.util.UUID;

public record CompetitionSummaryResponse(
        UUID id,
        String name,
        String organizationName,
        CompetitionStatus status
) {
}
