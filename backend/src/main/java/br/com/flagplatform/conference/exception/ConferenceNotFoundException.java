package br.com.flagplatform.conference.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class ConferenceNotFoundException extends ApiException {

    public ConferenceNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Conference not found",
                "Conference with id '%s' was not found.".formatted(id),
                "conference_not_found"
        );
    }

}