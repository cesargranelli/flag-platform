package br.com.flagplatform.organization.dto.response;

import java.util.UUID;

public record OrganizationCreatedResponse(
        UUID id,
        String tradeName,
        String message
) {
}
