package br.com.flagplatform.category.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class CategoryNotFoundException extends ApiException {

    public CategoryNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Category not found",
                "Category with id '%s' was not found.".formatted(id),
                "code"
        );
    }

}
