package br.com.flagplatform.team.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record UpdateTeamRequest(
        @NotNull
        UUID organizationId,

        @NotBlank
        @Size(max = 255)
        String name,

        @Size(max = 50)
        String shortName,

        @Size(max = 255)
        String sportName,

        @Size(max = 500)
        String logoUrl
) {
}
