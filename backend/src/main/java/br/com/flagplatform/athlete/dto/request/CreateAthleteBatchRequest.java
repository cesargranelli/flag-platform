package br.com.flagplatform.athlete.dto.request;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public record CreateAthleteBatchRequest(
        @NotEmpty
        List<CreateAthleteBatchItem> athletes
) {
}
