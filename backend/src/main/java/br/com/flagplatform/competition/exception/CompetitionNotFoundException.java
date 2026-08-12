package br.com.flagplatform.competition.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class CompetitionNotFoundException extends ApiException {

    public CompetitionNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Competition not found",
                "Competition with id '%s' was not found.".formatted(id),
                "code"
        );
    }

}
