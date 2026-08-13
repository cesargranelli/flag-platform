package br.com.flagplatform.game.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class TeamNotInGameException extends ApiException {

    public TeamNotInGameException(UUID gameId, UUID teamId) {
        super(
                HttpStatus.BAD_REQUEST,
                "Team not in game",
                "Team '%s' is not part of game '%s'.".formatted(teamId, gameId),
                "team_not_in_game"
        );
    }

}
