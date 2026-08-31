package br.com.flagplatform.team.dto.request;

import java.util.UUID;

/**
 * Corpo opcional da inscrição de um time em uma competição
 * (POST /api/v1/competitions/{competitionId}/teams/{teamId}).
 * A divisão, quando informada, deve pertencer à mesma competição.
 */
public record EnrollTeamRequest(
        UUID divisionId
) {
}