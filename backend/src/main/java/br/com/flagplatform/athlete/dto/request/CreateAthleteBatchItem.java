package br.com.flagplatform.athlete.dto.request;

import br.com.flagplatform.common.enums.AthletePosition;
import jakarta.validation.constraints.Size;

public record CreateAthleteBatchItem(
        @Size(max = 150)
        String name,

        @Size(max = 14)
        String cpf,

        @Size(max = 100)
        String nickname,

        AthletePosition position,

        Integer number,

        @Size(max = 500)
        String photoUrl
) {
}
