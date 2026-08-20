package br.com.flagplatform.conference.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateConferenceRequest(
        @NotBlank
        @Size(max = 100)
        String name
) {
}