package br.com.flagplatform.team.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record TeamResponse(
        UUID id,
        UUID categoryId,
        String name,
        String shortName,
        String logoUrl,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
