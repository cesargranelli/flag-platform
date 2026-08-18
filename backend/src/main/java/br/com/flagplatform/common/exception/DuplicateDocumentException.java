package br.com.flagplatform.common.exception;

import org.springframework.http.HttpStatus;

public class DuplicateDocumentException extends ApiException {

    public DuplicateDocumentException(String document) {
        super(
                HttpStatus.CONFLICT,
                "Duplicate document",
                "Document '%s' is already in use.".formatted(document),
                "code"
        );
    }

}
