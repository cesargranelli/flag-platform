package br.com.flagplatform.user.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class EmailAlreadyExistsException extends ApiException {

    public EmailAlreadyExistsException(String email) {
        super(
                HttpStatus.CONFLICT,
                "Email already registered",
                "A user with email '%s' already exists.".formatted(email),
                "code"
        );
    }

}
