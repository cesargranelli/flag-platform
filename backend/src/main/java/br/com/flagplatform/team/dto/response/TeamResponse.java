package br.com.flagplatform.team.dto.response;

import br.com.flagplatform.common.enums.DocumentType;

import java.time.LocalDateTime;
import java.util.UUID;

public record TeamResponse(
        UUID id,
        UUID categoryId,
        UUID divisionId,
        String name,
        String shortName,
        String document,
        DocumentType documentType,
        String logoUrl,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
