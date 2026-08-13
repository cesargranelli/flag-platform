package br.com.flagplatform.venue.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record VenueResponse(
        UUID id,
        UUID organizationId,
        String name,
        String address,
        String mapsUrl,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
