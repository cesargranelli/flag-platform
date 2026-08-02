package br.com.flagplatform.organization.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

public class OrganizationInactiveException extends ApiException {

    public OrganizationInactiveException() {
        super(
                HttpStatus.FORBIDDEN,
                "Organization inactive",
                "The organization is inactive.",
                "code"
        );
    }

}
