package br.com.flagplatform.team.dto.response;

import br.com.flagplatform.common.enums.OrganizationStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record TeamResponse(
        UUID id,
        UUID organizationId,
        String organizationName,
        String name,
        String shortName,
        String sportName,
        String logoUrl,
        OrganizationStatus status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}