package br.com.flagplatform.organization.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class InvalidOrganizationHierarchyException extends ApiException {

    public InvalidOrganizationHierarchyException(String detail) {
        super(
                HttpStatus.BAD_REQUEST,
                "Invalid organization hierarchy",
                detail,
                "invalid_organization_hierarchy"
        );
    }

}