package br.com.flagplatform.division.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class ConferenceCompetitionMismatchException extends ApiException {

    public ConferenceCompetitionMismatchException() {
        super(
                HttpStatus.BAD_REQUEST,
                "Conference competition mismatch",
                "The conference does not belong to the same competition as the division.",
                "conference_competition_mismatch"
        );
    }

}