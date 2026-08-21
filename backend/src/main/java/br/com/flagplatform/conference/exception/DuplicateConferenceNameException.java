package br.com.flagplatform.conference.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class DuplicateConferenceNameException extends ApiException {

    public DuplicateConferenceNameException(String name) {
        super(
                HttpStatus.CONFLICT,
                "Duplicate conference name",
                "A conference named '%s' already exists in this competition.".formatted(name),
                "duplicate_conference_name"
        );
    }

}