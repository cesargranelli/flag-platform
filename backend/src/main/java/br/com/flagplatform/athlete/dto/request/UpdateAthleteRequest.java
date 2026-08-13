package br.com.flagplatform.athlete.dto.request;

import br.com.flagplatform.common.enums.AthletePosition;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record UpdateAthleteRequest(
        @NotBlank
        @Size(max = 150)
        String name,

        @Size(max = 100)
        String nickname,

        AthletePosition position,

        @Positive
        Integer number,

        @Size(max = 500)
        String photoUrl
) {
}
