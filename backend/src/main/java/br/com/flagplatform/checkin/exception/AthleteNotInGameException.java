package br.com.flagplatform.checkin.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class AthleteNotInGameException extends ApiException {

    public AthleteNotInGameException(UUID gameId, UUID athleteId) {
        super(
                HttpStatus.BAD_REQUEST,
                "Athlete not in game",
                "Athlete '%s' is not part of the rosters of game '%s'.".formatted(athleteId, gameId),
                "code"
        );
    }

}
