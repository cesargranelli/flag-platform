package br.com.flagplatform.game.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class GameNotFoundException extends ApiException {

    public GameNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Game not found",
                "Game with id '%s' was not found.".formatted(id),
                "game_not_found"
        );
    }

}
