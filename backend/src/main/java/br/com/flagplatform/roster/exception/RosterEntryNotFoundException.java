package br.com.flagplatform.roster.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class RosterEntryNotFoundException extends ApiException {

    public RosterEntryNotFoundException(UUID teamId, UUID athleteId) {
        super(
                HttpStatus.NOT_FOUND,
                "Roster entry not found",
                "Athlete '%s' is not registered in team '%s'.".formatted(athleteId, teamId),
                "code"
        );
    }

}
