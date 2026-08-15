package br.com.flagplatform.user.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class UserNotFoundException extends ApiException {

    public UserNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "User not found",
                "User with id '%s' was not found.".formatted(id),
                "user_not_found"
        );
    }

}
