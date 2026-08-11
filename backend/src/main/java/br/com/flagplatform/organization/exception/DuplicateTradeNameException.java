package br.com.flagplatform.organization.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class DuplicateTradeNameException extends ApiException {

    public DuplicateTradeNameException(String tradeName) {
        super(
                HttpStatus.CONFLICT,
                "Duplicate trade name",
                "Organization with trade name '%s' already exists.".formatted(tradeName),
                "code"
        );
    }

}
