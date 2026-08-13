package br.com.flagplatform.standing.dto.response;

import java.util.UUID;

public record StandingResponse(
        int position,
        UUID teamId,
        String teamName,
        int played,
        int wins,
        int draws,
        int losses,
        int goalsFor,
        int goalsAgainst,
        int goalDifference,
        int points
) {
}
