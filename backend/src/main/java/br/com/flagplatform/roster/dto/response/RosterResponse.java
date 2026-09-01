package br.com.flagplatform.roster.dto.response;

import br.com.flagplatform.common.enums.RosterStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record RosterResponse(
        UUID id,
        UUID teamId,
        UUID competitionId,
        String name,
        String season,
        RosterStatus status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}