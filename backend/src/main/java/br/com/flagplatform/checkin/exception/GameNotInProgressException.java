package br.com.flagplatform.checkin.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class GameNotInProgressException extends ApiException {

    public GameNotInProgressException(UUID gameId) {
        super(
                HttpStatus.CONFLICT,
                "Game not in progress",
                "Game '%s' is not in progress, so athletes cannot be validated.".formatted(gameId),
                "code"
        );
    }

}
