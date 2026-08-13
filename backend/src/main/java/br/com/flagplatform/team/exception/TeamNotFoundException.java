package br.com.flagplatform.team.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class TeamNotFoundException extends ApiException {

    public TeamNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Team not found",
                "Team with id '%s' was not found.".formatted(id),
                "team_not_found"
        );
    }

}
