package br.com.flagplatform.division.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class ConferenceCategoryMismatchException extends ApiException {

    public ConferenceCategoryMismatchException() {
        super(
                HttpStatus.BAD_REQUEST,
                "Conference category mismatch",
                "The conference does not belong to the same category as the division.",
                "conference_category_mismatch"
        );
    }

}