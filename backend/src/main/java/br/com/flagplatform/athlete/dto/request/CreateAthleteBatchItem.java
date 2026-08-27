package br.com.flagplatform.athlete.dto.request;

import br.com.flagplatform.common.enums.AthletePosition;
import jakarta.validation.constraints.Size;

import java.util.List;

public record CreateAthleteBatchItem(
        @Size(max = 150)
        String name,

        @Size(max = 14)
        String cpf,

        @Size(max = 100)
        String nickname,

        @Size(max = 3)
        List<AthletePosition> positions,

        Integer number,

        @Size(max = 500)
        String photoUrl
) {
}
