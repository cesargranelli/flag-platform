package br.com.flagplatform.team.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateTeamRequest(
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