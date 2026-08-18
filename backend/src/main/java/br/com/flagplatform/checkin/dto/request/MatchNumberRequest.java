package br.com.flagplatform.checkin.dto.request;

import jakarta.validation.constraints.Positive;

public record MatchNumberRequest(
        @Positive
        Integer number
) {
}
