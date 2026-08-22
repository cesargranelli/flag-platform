package br.com.flagplatform.organization.dto.request;

import br.com.flagplatform.common.enums.DocumentType;
import br.com.flagplatform.common.enums.OrganizationType;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateOrganizationRequest(
        @NotBlank
        @Size(max = 150)
        String legalName,

        @NotBlank
        @Size(max = 100)
        String tradeName,

        @Size(max = 20)
        String abbreviation,

        OrganizationType organizationType,

        @Size(max = 20)
        String document,

        DocumentType documentType,

        @NotBlank
        @Size(max = 150)
        String presidentName,

        @NotBlank
        @Size(max = 14)
        String presidentCpf,

        @Email
        @Size(max = 150)
        String email,

        @Size(max = 30)
        String phone,

        @Size(max = 255)
        String website,

        @Size(max = 100)
        String instagram,

        @NotBlank
        @Size(min = 2, max = 2)
        String country,

        @Size(max = 100)
        String state,

        @Size(max = 100)
        String city,

        @Size(max = 500)
        String logoUrl,

        @Size(max = 7)
        String primaryColor,

        @Size(max = 7)
        String secondaryColor,

        @Size(max = 7)
        String tertiaryColor,

        @Size(max = 7)
        String quaternaryColor,

        @NotBlank
        String timezone,

        @NotBlank
        String locale
) {
}
