package br.com.flagplatform.organization.dto.response;

import br.com.flagplatform.common.enums.DocumentType;
import br.com.flagplatform.common.enums.OrganizationStatus;
import br.com.flagplatform.common.enums.OrganizationType;

import java.time.LocalDateTime;
import java.util.UUID;

public record OrganizationResponse(
        UUID id,
        UUID parentId,
        String legalName,
        String tradeName,
        String abbreviation,
        OrganizationType organizationType,
        String document,
        DocumentType documentType,
        String presidentName,
        String presidentCpf,
        String email,
        String phone,
        String website,
        String instagram,
        String country,
        String state,
        String city,
        String logoUrl,
        String primaryColor,
        String secondaryColor,
        String tertiaryColor,
        String quaternaryColor,
        String timezone,
        String locale,
        OrganizationStatus status,
        UUID createdBy,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
