package br.com.flagplatform.team.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class DivisionCategoryMismatchException extends ApiException {

    public DivisionCategoryMismatchException() {
        super(
                HttpStatus.BAD_REQUEST,
                "Division category mismatch",
                "The division does not belong to the same category as the team.",
                "division_category_mismatch"
        );
    }

}