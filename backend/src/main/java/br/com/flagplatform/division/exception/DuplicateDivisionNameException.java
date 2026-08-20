package br.com.flagplatform.division.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class DuplicateDivisionNameException extends ApiException {

    public DuplicateDivisionNameException(String name) {
        super(
                HttpStatus.CONFLICT,
                "Duplicate division name",
                "A division named '%s' already exists in this group.".formatted(name),
                "duplicate_division_name"
        );
    }

}