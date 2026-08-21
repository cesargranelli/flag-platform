package br.com.flagplatform.team.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class DuplicateTeamRegistrationException extends ApiException {

    public DuplicateTeamRegistrationException(UUID organizationId, UUID competitionId) {
        super(
                HttpStatus.CONFLICT,
                "Duplicate team registration",
                "The organization '%s' already has a team registered in this competition.".formatted(organizationId),
                "duplicate_team_registration"
        );
    }

}
