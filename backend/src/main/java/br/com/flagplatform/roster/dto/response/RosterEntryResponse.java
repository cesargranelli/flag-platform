package br.com.flagplatform.roster.dto.response;

import br.com.flagplatform.common.enums.AthletePosition;
import br.com.flagplatform.common.enums.RosterStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record RosterEntryResponse(
        UUID id,
        UUID rosterId,
        UUID athleteId,
        String athleteName,
        String athleteNickname,
        String nickname,
        AthletePosition position,
        Integer number,
        String photoUrl,
        RosterStatus status,
        LocalDateTime createdAt
) {
}
