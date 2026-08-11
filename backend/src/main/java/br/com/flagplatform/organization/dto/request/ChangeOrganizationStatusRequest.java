package br.com.flagplatform.organization.dto.request;

import br.com.flagplatform.common.enums.OrganizationStatus;
import jakarta.validation.constraints.NotNull;

public record ChangeOrganizationStatusRequest(
        @NotNull
        OrganizationStatus status
) {
}
