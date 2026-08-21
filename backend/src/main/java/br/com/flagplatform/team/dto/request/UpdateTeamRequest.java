package br.com.flagplatform.team.dto.request;

import br.com.flagplatform.common.enums.DocumentType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record UpdateTeamRequest(
        @NotNull
        UUID organizationId,

        @NotNull
        UUID competitionId,

        UUID divisionId,

        @NotBlank
        @Size(max = 150)
        String name,

        @Size(max = 20)
        String shortName,

        @Size(max = 20)
        String document,

        DocumentType documentType,

        @Size(max = 500)
        String logoUrl
) {
}
