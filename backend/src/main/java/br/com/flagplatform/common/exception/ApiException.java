package br.com.flagplatform.common.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.ErrorResponseException;

@Getter
public abstract class ApiException extends ErrorResponseException {

    private final String code;

    protected ApiException(
            HttpStatus status,
            String title,
            String detail,
            String code) {

        super(status, createProblemDetail(status, title, detail), null);
        this.code = code;
    }

    private static ProblemDetail createProblemDetail(
            HttpStatus status,
            String title,
            String detail) {

        ProblemDetail problem = ProblemDetail.forStatusAndDetail(status, detail);
        problem.setTitle(title);

        return problem;
    }

}
