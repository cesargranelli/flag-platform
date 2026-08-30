package br.com.flagplatform.play.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class PlayNotFoundException extends ApiException {

    public PlayNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Play not found",
                "Play with id '%s' was not found.".formatted(id),
                "play_not_found"
        );
    }
}
