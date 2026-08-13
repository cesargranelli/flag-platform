package br.com.flagplatform.checkin.dto.response;

import br.com.flagplatform.common.enums.CheckInStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record ValidationResponse(
        UUID gameId,
        UUID teamId,
        UUID athleteId,
        String athleteName,
        CheckInStatus status,
        UUID validatedBy,
        LocalDateTime validatedAt
) {
}
