package br.com.flagplatform.competition.dto.request;

import br.com.flagplatform.common.enums.CompetitionStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.UUID;

public record UpdateCompetitionRequest(
        @NotNull
        UUID organizationId,

        @NotBlank
        @Size(max = 100)
        String name,

        @Size(max = 500)
        String description,

        LocalDate startDate,

        LocalDate endDate,

        CompetitionStatus status
) {
}
