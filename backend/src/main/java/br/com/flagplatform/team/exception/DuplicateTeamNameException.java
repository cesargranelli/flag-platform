package br.com.flagplatform.team.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class DuplicateTeamNameException extends ApiException {

    public DuplicateTeamNameException(String name) {
        super(
                HttpStatus.CONFLICT,
                "Duplicate team name",
                "A team named '%s' already exists in this category.".formatted(name),
                "duplicate_team_name"
        );
    }

}
