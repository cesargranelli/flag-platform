package br.com.flagplatform.conference.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record ConferenceResponse(
        UUID id,
        UUID categoryId,
        String name,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}