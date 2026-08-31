package br.com.flagplatform.competition.dto.response;

import br.com.flagplatform.common.enums.AgeGroup;
import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.common.enums.Gender;
import br.com.flagplatform.common.enums.GroupingType;
import br.com.flagplatform.common.enums.Modality;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record CompetitionResponse(
        UUID id,
        UUID organizationId,
        String organizationName,
        Modality modality,
        Gender gender,
        AgeGroup ageGroup,
        String name,
        String description,
        LocalDate startDate,
        LocalDate endDate,
        CompetitionStatus status,
        GroupingType groupingType,
        String season,
        UUID createdBy,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
