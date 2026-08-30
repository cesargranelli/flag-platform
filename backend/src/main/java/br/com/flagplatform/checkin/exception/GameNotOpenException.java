package br.com.flagplatform.checkin.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class GameNotOpenException extends ApiException {

    public GameNotOpenException(UUID gameId) {
        super(
                HttpStatus.CONFLICT,
                "Game not open",
                "Game '%s' is not open, so the check-in/conference of athletes is not allowed.".formatted(gameId),
                "game_not_open"
        );
    }

}