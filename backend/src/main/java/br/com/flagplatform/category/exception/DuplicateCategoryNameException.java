package br.com.flagplatform.category.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class DuplicateCategoryNameException extends ApiException {

    public DuplicateCategoryNameException(String name) {
        super(
                HttpStatus.CONFLICT,
                "Duplicate category name",
                "Category with name '%s' already exists for this competition.".formatted(name),
                "code"
        );
    }

}
