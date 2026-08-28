package br.com.flagplatform.play.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class PlayTeamNotInGameException extends ApiException {

    public PlayTeamNotInGameException(UUID gameId, UUID teamId) {
        super(
                HttpStatus.BAD_REQUEST,
                "Team not in game",
                "Team '%s' is not a participant of game '%s'.".formatted(teamId, gameId),
                "play_team_not_in_game"
        );
    }
}
