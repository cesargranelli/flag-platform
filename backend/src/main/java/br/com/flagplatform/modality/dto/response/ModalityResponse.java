package br.com.flagplatform.modality.dto.response;

import br.com.flagplatform.common.enums.ContactType;

import java.time.LocalDateTime;
import java.util.UUID;

public record ModalityResponse(
        UUID id,
        String name,
        String format,
        ContactType contactType,
        Integer playersPerTeam,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
