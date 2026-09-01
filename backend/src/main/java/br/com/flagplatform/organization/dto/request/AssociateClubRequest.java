package br.com.flagplatform.organization.dto.request;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record AssociateClubRequest(
        @NotNull
        UUID organizationId
) {
}