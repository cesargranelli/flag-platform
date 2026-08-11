package br.com.flagplatform.common.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.ErrorResponseException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.List;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ValidationErrorResponse> handleValidation(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {

        List<ValidationFieldError> fields = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(this::toFieldError)
                .toList();

        ValidationErrorResponse response = new ValidationErrorResponse(
                Instant.now(),
                HttpStatus.BAD_REQUEST.value(),
                HttpStatus.BAD_REQUEST.getReasonPhrase(),
                "Validation failed",
                request.getRequestURI(),
                fields
        );

        return ResponseEntity.badRequest().body(response);
    }

    @ExceptionHandler(ErrorResponseException.class)
    public ResponseEntity<ErrorResponse> handle(
            ErrorResponseException ex,
            HttpServletRequest request) {

        ProblemDetail problem = ex.getBody();

        ErrorResponse response = new ErrorResponse(
                Instant.now(),
                problem.getStatus(),
                problem.getTitle(),
                problem.getDetail(),
                request.getRequestURI()
        );

        return ResponseEntity
                .status(problem.getStatus())
                .body(response);
    }

    private ValidationFieldError toFieldError(FieldError error) {
        return new ValidationFieldError(
                error.getField(),
                error.getDefaultMessage()
        );
    }
}