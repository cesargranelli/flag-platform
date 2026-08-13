package br.com.flagplatform.venue.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class DuplicateVenueNameException extends ApiException {

    public DuplicateVenueNameException(String name) {
        super(
                HttpStatus.CONFLICT,
                "Duplicate venue name",
                "A venue named '%s' already exists in this organization.".formatted(name),
                "duplicate_venue_name"
        );
    }

}
