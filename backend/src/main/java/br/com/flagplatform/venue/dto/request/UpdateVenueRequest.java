package br.com.flagplatform.venue.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record UpdateVenueRequest(
        @NotNull
        UUID organizationId,

        @NotBlank
        @Size(max = 150)
        String name,

        @Size(max = 500)
        String address,

        @Size(max = 500)
        String mapsUrl
) {
}
