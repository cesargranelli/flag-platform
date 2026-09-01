package br.com.flagplatform.athlete.dto.request;

import br.com.flagplatform.common.enums.AthletePosition;
import br.com.flagplatform.common.enums.Gender;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.List;

public record CreateAthleteRequest(
        @NotBlank
        @Size(max = 150)
        String name,

        @NotBlank
        @Size(max = 14)
        String cpf,

        @Size(max = 100)
        String nickname,

        @Size(max = 3)
        List<AthletePosition> positions,

        @Positive
        Integer number,

        @Size(max = 500)
        String photoUrl,

        LocalDate birthDate,

        Gender gender
) {
}
