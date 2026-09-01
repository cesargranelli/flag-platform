package br.com.flagplatform.organization.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class OrganizationAssociationNotFoundException extends ApiException {

    public OrganizationAssociationNotFoundException(UUID parentId, UUID childId) {
        super(
                HttpStatus.NOT_FOUND,
                "Organization association not found",
                "The organization '%s' is not associated to organization '%s'."
                        .formatted(childId, parentId),
                "organization_association_not_found"
        );
    }

}