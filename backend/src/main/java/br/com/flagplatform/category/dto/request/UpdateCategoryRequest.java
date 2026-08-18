package br.com.flagplatform.category.dto.request;

import br.com.flagplatform.common.enums.AgeGroup;
import br.com.flagplatform.common.enums.Gender;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record UpdateCategoryRequest(
        @NotNull
        UUID competitionId,

        @NotNull
        UUID modalityId,

        @NotNull
        Gender gender,

        @NotNull
        AgeGroup ageGroup,

        @Size(max = 100)
        String name
) {
}
