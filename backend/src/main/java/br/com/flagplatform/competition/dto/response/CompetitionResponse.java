package br.com.flagplatform.competition.dto.response;

import br.com.flagplatform.common.enums.CompetitionStatus;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record CompetitionResponse(
        UUID id,
        UUID organizationId,
        String name,
        String description,
        LocalDate startDate,
        LocalDate endDate,
        CompetitionStatus status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
