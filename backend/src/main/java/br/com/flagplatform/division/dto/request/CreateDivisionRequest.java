package br.com.flagplatform.division.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateDivisionRequest(
        UUID conferenceId,

        @NotBlank
        @Size(max = 100)
        String name
) {
}