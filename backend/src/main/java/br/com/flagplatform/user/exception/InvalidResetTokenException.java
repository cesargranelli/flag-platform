package br.com.flagplatform.user.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class InvalidResetTokenException extends ApiException {

    public InvalidResetTokenException() {
        super(
                HttpStatus.BAD_REQUEST,
                "Invalid reset token",
                "The password reset token is invalid, expired or already used.",
                "invalid_reset_token"
        );
    }

}
