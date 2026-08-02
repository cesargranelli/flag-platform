package br.com.flagplatform.organization.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class OrganizationNotFoundException extends ApiException {

    public OrganizationNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Organization not found",
                "Organization with id '%s' was not found.".formatted(id),
                "code"
        );
    }

}
