package br.com.flagplatform.roster.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class DuplicateRosterEntryException extends ApiException {

    public DuplicateRosterEntryException() {
        super(
                HttpStatus.CONFLICT,
                "Duplicate roster entry",
                "The athlete is already registered in this team.",
                "code"
        );
    }

}
