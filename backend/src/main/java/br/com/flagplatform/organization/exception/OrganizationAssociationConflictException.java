package br.com.flagplatform.organization.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class OrganizationAssociationConflictException extends ApiException {

    public OrganizationAssociationConflictException(UUID childId, UUID parentId) {
        super(
                HttpStatus.CONFLICT,
                "Organization already associated",
                "The organization '%s' is already associated to organization '%s'."
                        .formatted(childId, parentId),
                "organization_already_associated"
        );
    }

}