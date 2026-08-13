package br.com.flagplatform.user.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class InvalidCredentialsException extends ApiException {

    public InvalidCredentialsException() {
        super(
                HttpStatus.UNAUTHORIZED,
                "Invalid credentials",
                "Email or password is invalid.",
                "code"
        );
    }

}
