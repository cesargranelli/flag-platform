package br.com.flagplatform.category.dto.response;

import br.com.flagplatform.common.enums.AgeGroup;
import br.com.flagplatform.common.enums.Gender;

import java.time.LocalDateTime;
import java.util.UUID;

public record CategoryResponse(
        UUID id,
        UUID competitionId,
        UUID modalityId,
        String modalityName,
        String modalityFormat,
        Gender gender,
        AgeGroup ageGroup,
        String name,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
