package br.com.flagplatform.game.exception;

import br.com.flagplatform.common.enums.GameStatus;
import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class GameNotInProgressException extends ApiException {

    public GameNotInProgressException(GameStatus status) {
        super(
                HttpStatus.CONFLICT,
                "Game not in progress",
                "Cannot register a result for a game in status '%s'.".formatted(status),
                "game_not_in_progress"
        );
    }

}
