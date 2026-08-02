package br.com.flagplatform.common.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.ErrorResponseException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;

@RestControllerAdvice
public class GlobalExceptionHandler {

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

//    @ExceptionHandler(MethodArgumentNotValidException.class)
//    public ResponseEntity<ValidationErrorResponse> handleValidationException(
//            MethodArgumentNotValidException ex,
//            HttpServletRequest request) {
//
//        List<ValidationFieldError> fields = ex.getBindingResult()
//                .getFieldErrors()
//                .stream()
//                .map(this::toFieldError)
//                .toList();
//
//        ValidationErrorResponse response =
//                new ValidationErrorResponse(
//                        Instant.now(),
//                        HttpStatus.BAD_REQUEST.value(),
//                        HttpStatus.BAD_REQUEST.getReasonPhrase(),
//                        "Validation failed",
//                        request.getRequestURI(),
//                        fields
//                );
//
//        return ResponseEntity.badRequest().body(response);
//    }
//
//    @ExceptionHandler(ErrorResponseException.class)
//    public ResponseEntity<ErrorResponse> handleErrorResponseException(
//            ErrorResponseException ex,
//            HttpServletRequest request) {
//
//        ProblemDetail problem = ex.getBody();
//
//        ErrorResponse response =
//                new ErrorResponse(
//                        Instant.now(),
//                        problem.getStatus(),
//                        problem.getTitle(),
//                        problem.getDetail(),
//                        request.getRequestURI()
//                );
//
//        return ResponseEntity
//                .status(problem.getStatus())
//                .body(response);
//    }
//
//    @ExceptionHandler(Exception.class)
//    public ResponseEntity<ErrorResponse> handleException(
//            Exception ex,
//            HttpServletRequest request) {
//
//        ErrorResponse response =
//                new ErrorResponse(
//                        Instant.now(),
//                        HttpStatus.INTERNAL_SERVER_ERROR.value(),
//                        HttpStatus.INTERNAL_SERVER_ERROR.getReasonPhrase(),
//                        ex.getMessage(),
//                        request.getRequestURI()
//                );
//
//        return ResponseEntity
//                .status(HttpStatus.INTERNAL_SERVER_ERROR)
//                .body(response);
//    }
//
//    private ValidationFieldError toFieldError(FieldError error) {
//        return new ValidationFieldError(
//                error.getField(),
//                error.getDefaultMessage()
//        );
//    }
}