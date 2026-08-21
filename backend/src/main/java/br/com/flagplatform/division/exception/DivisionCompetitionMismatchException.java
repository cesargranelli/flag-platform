package br.com.flagplatform.division.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class DivisionCompetitionMismatchException extends ApiException {

    public DivisionCompetitionMismatchException() {
        super(
                HttpStatus.BAD_REQUEST,
                "Division competition mismatch",
                "The division does not belong to the same competition as the team.",
                "division_competition_mismatch"
        );
    }

}