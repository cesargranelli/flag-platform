package br.com.flagplatform.category.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record CategoryResponse(
        UUID id,
        UUID competitionId,
        String name,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
