package br.com.flagplatform.team.dto.request;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record EnrollTeamRequest(
        @NotNull
        UUID teamId,

        UUID divisionId
) {
}
