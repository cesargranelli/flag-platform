package br.com.flagplatform.competition.dto.response;

import br.com.flagplatform.common.enums.AgeGroup;
import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.common.enums.Gender;
import br.com.flagplatform.common.enums.Modality;

import java.util.UUID;

public record CompetitionSummaryResponse(
        UUID id,
        String name,
        String organizationName,
        CompetitionStatus status,
        Modality modality,
        Gender gender,
        AgeGroup ageGroup,
        UUID createdBy
) {
}
