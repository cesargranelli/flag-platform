package br.com.flagplatform.round.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class RoundNotFoundException extends ApiException {

    public RoundNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Round not found",
                "Round with id '%s' was not found.".formatted(id),
                "round_not_found"
        );
    }

}
