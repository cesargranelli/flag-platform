package br.com.flagplatform.team.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateTeamRequest(
        @NotNull
        UUID categoryId,

        @NotBlank
        @Size(max = 150)
        String name,

        @Size(max = 20)
        String shortName,

        @Size(max = 500)
        String logoUrl
) {
}
