package br.com.flagplatform.venue.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class VenueNotFoundException extends ApiException {

    public VenueNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Venue not found",
                "Venue with id '%s' was not found.".formatted(id),
                "venue_not_found"
        );
    }

}
