package br.com.flagplatform.game.exception;

import br.com.flagplatform.common.enums.GameStatus;
import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class InvalidGameStatusTransitionException extends ApiException {

    public InvalidGameStatusTransitionException(GameStatus current, GameStatus requested) {
        super(
                HttpStatus.CONFLICT,
                "Invalid game status transition",
                "Cannot transition game status from '%s' to '%s'.".formatted(current, requested),
                "invalid_game_status_transition"
        );
    }

}
