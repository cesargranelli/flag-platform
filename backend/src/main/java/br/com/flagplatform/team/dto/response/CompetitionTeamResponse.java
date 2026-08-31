package br.com.flagplatform.team.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record CompetitionTeamResponse(
        UUID id,
        UUID competitionId,
        UUID teamId,
        String teamName,
        UUID divisionId,
        LocalDateTime createdAt
) {
}
