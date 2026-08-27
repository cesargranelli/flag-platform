package br.com.flagplatform.athlete.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class InvalidAthletePositionsException extends ApiException {

    public InvalidAthletePositionsException(String message) {
        super(
                HttpStatus.BAD_REQUEST,
                "Invalid athlete positions",
                message,
                "code"
        );
    }

}
