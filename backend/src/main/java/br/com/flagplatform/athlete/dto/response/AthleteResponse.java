package br.com.flagplatform.athlete.dto.response;

import br.com.flagplatform.common.enums.AthletePosition;

import java.time.LocalDateTime;
import java.util.UUID;

public record AthleteResponse(
        UUID id,
        String name,
        String nickname,
        AthletePosition position,
        Integer number,
        String photoUrl,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
