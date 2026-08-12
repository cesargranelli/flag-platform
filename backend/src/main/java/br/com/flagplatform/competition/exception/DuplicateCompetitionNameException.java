package br.com.flagplatform.competition.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class DuplicateCompetitionNameException extends ApiException {

    public DuplicateCompetitionNameException(String name) {
        super(
                HttpStatus.CONFLICT,
                "Duplicate competition name",
                "Competition with name '%s' already exists for this organization.".formatted(name),
                "code"
        );
    }

}
