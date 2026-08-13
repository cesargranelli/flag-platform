package br.com.flagplatform.game.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class SameTeamGameException extends ApiException {

    public SameTeamGameException() {
        super(
                HttpStatus.BAD_REQUEST,
                "Same team in game",
                "Home and away teams must be different.",
                "same_team_in_game"
        );
    }

}
