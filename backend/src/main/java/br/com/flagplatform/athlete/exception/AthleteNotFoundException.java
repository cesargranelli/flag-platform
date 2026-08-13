package br.com.flagplatform.athlete.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class AthleteNotFoundException extends ApiException {

    public AthleteNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Athlete not found",
                "Athlete with id '%s' was not found.".formatted(id),
                "code"
        );
    }

}
