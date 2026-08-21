package br.com.flagplatform.round.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class DuplicateRoundNumberException extends ApiException {

    public DuplicateRoundNumberException(Integer number) {
        super(
                HttpStatus.CONFLICT,
                "Duplicate round number",
                "A round with number '%d' already exists in this competition.".formatted(number),
                "duplicate_round_number"
        );
    }

}
