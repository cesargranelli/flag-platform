package br.com.flagplatform.athlete.dto.response;

import br.com.flagplatform.common.enums.AthletePosition;
import br.com.flagplatform.common.enums.AthleteStatus;
import br.com.flagplatform.common.enums.Gender;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record AthleteResponse(
        UUID id,
        String name,
        String cpf,
        String nickname,
        List<AthletePosition> positions,
        Integer number,
        String photoUrl,
        AthleteStatus status,
        LocalDate birthDate,
        Gender gender,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
