package br.com.flagplatform.checkin.dto.response;

import br.com.flagplatform.common.enums.AthletePosition;
import br.com.flagplatform.common.enums.CheckInStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record CheckInResponse(
        UUID gameId,
        UUID teamId,
        String teamName,
        UUID athleteId,
        String athleteName,
        String athleteNickname,
        Integer number,
        Integer athleteNumber,
        Integer matchNumber,
        AthletePosition position,
        CheckInStatus status,
        UUID validatedBy,
        LocalDateTime validatedAt
) {
}
