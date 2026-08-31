package br.com.flagplatform.competition.dto.request;

import br.com.flagplatform.common.enums.AgeGroup;
import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.common.enums.Gender;
import br.com.flagplatform.common.enums.GroupingType;
import br.com.flagplatform.common.enums.Modality;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.UUID;

public record CreateCompetitionRequest(
        @NotNull
        UUID organizationId,

        @NotNull
        Modality modality,

        // Issue #286: obrigatórios — alinhados à exigência da UI.
        @NotNull
        Gender gender,

        @NotNull
        AgeGroup ageGroup,

        @NotBlank
        @Size(max = 100)
        String name,

        @Size(max = 500)
        String description,

        LocalDate startDate,

        LocalDate endDate,

        CompetitionStatus status,

        // Issue #308: rótulo do agrupamento — DIVISIONS (default) | GROUPS.
        GroupingType groupingType,

        @NotBlank
        @Size(max = 50)
        String season
) {
}
