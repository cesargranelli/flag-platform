package br.com.flagplatform.category.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateCategoryRequest(
        @NotNull
        UUID competitionId,

        @NotBlank
        @Size(max = 100)
        String name
) {
}
