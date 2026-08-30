package br.com.flagplatform.team.dto.request;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * Corpo da associação de um clube (organização) a um campeonato (#377):
 * apenas o id da organização é necessário; o nome do time é derivado do
 * próprio clube no serviço.
 */
public record AssociateClubRequest(
        @NotNull
        UUID organizationId
) {
}
