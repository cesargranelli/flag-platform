package br.com.flagplatform.checkin.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class DuplicateMatchNumberException extends ApiException {

    public DuplicateMatchNumberException(UUID gameId, int number) {
        super(
                HttpStatus.CONFLICT,
                "Duplicate match number",
                "Another athlete already uses number '%d' in this match (game '%s')."
                        .formatted(number, gameId),
                "code"
        );
    }

}
