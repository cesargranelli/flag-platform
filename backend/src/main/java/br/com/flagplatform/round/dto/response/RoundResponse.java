package br.com.flagplatform.round.dto.response;

import br.com.flagplatform.common.enums.RoundType;

import java.time.LocalDateTime;
import java.util.UUID;

public record RoundResponse(
        UUID id,
        UUID competitionId,
        Integer number,
        String name,
        RoundType type,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
