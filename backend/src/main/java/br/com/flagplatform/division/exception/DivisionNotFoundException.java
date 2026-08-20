package br.com.flagplatform.division.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class DivisionNotFoundException extends ApiException {

    public DivisionNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Division not found",
                "Division with id '%s' was not found.".formatted(id),
                "division_not_found"
        );
    }

}