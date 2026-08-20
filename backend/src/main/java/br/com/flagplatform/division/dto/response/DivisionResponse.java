package br.com.flagplatform.division.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record DivisionResponse(
        UUID id,
        UUID categoryId,
        UUID conferenceId,
        String name,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}