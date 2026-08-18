package br.com.flagplatform.common.exception;

import org.springframework.http.HttpStatus;

public class InvalidDocumentException extends ApiException {

    public InvalidDocumentException(String message) {
        super(
                HttpStatus.BAD_REQUEST,
                "Invalid document",
                message,
                "code"
        );
    }

}
