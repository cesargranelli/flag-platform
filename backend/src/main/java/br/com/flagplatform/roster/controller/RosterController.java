package br.com.flagplatform.roster.controller;

import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.roster.dto.request.AddRosterEntryRequest;
import br.com.flagplatform.roster.dto.request.RosterBatchRequest;
import br.com.flagplatform.roster.dto.response.RosterEntryResponse;
import br.com.flagplatform.roster.dto.response.RosterBatchResponse;
import br.com.flagplatform.roster.dto.response.RosterResponse;
import br.com.flagplatform.roster.service.RosterService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Roster", description = "Endpoints para gerenciar o elenco dos times")
@RestController
@RequiredArgsConstructor
public class RosterController {

    private final RosterService service;

    @Operation(
            summary = "Inscrever atleta no time",
            description = "Adiciona um atleta ao elenco de um time em uma competição. Permitido apenas para ADMIN ou ORGANIZER."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é ADMIN nem ORGANIZER")
    @PostMapping("/api/v1/teams/{teamId}/competitions/{competitionId}/roster")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public RosterEntryResponse add(
            @Parameter(description = "Id do time") @PathVariable UUID teamId,
            @Parameter(description = "Id da competição") @PathVariable UUID competitionId,
            @Valid @RequestBody AddRosterEntryRequest request,
            Authentication authentication) {
        return service.add(teamId, competitionId, request, authentication.getName());
    }

    @Operation(
            summary = "Importar elenco em lote",
            description = "Inscreve varios atletas em um time de uma vez para uma competição. Atletas ja inscritos sao pulados. Permitido apenas para ADMIN ou ORGANIZER."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é ADMIN nem ORGANIZER")
    @PostMapping("/api/v1/teams/{teamId}/competitions/{competitionId}/roster/batch")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public RosterBatchResponse createBatch(
            @Parameter(description = "Id do time") @PathVariable UUID teamId,
            @Parameter(description = "Id da competição") @PathVariable UUID competitionId,
            @Valid @RequestBody RosterBatchRequest request,
            Authentication authentication) {
        return service.createBatch(teamId, competitionId, request, authentication.getName());
    }

    @Operation(
            summary = "Listar elencos do time",
            description = "Lista todos os elencos (rosters) de um time, independente da competição, ordenados por criação (mais recentes primeiro). Acesso público."
    )
    @GetMapping("/api/v1/teams/{teamId}/rosters")
    public List<RosterResponse> findRostersByTeam(
            @Parameter(description = "Id do time") @PathVariable UUID teamId) {
        return service.findByTeamId(teamId);
    }

    @Operation(
            summary = "Listar elenco do time na competição",
            description = "Lista os atletas inscritos em um time para uma competição, ordenados por nome. Acesso público."
    )
    @GetMapping("/api/v1/teams/{teamId}/competitions/{competitionId}/roster")
    public List<RosterEntryResponse> findRosterByTeamAndCompetition(
            @Parameter(description = "Id do time") @PathVariable UUID teamId,
            @Parameter(description = "Id da competição") @PathVariable UUID competitionId) {
        return service.findRosterByTeamAndCompetition(teamId, competitionId);
    }

    @Operation(
            summary = "Remover atleta do time",
            description = "Remove um atleta do elenco de um time em uma competição. Permitido apenas para ADMIN ou ORGANIZER."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é ADMIN nem ORGANIZER")
    @DeleteMapping("/api/v1/teams/{teamId}/competitions/{competitionId}/roster/{athleteId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void remove(
            @Parameter(description = "Id do time") @PathVariable UUID teamId,
            @Parameter(description = "Id da competição") @PathVariable UUID competitionId,
            @Parameter(description = "Id do atleta") @PathVariable UUID athleteId,
            Authentication authentication) {
        service.remove(teamId, competitionId, athleteId, authentication.getName());
    }

    @Operation(
            summary = "Desativar elenco do time na competição",
            description = "Marca o elenco (roster) de um time em uma competição como INACTIVE. "
                    + "Permitido apenas para ADMIN ou ORGANIZER."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é ADMIN nem ORGANIZER")
    @PostMapping("/api/v1/teams/{teamId}/competitions/{competitionId}/roster/deactivate")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void deactivate(
            @Parameter(description = "Id do time") @PathVariable UUID teamId,
            @Parameter(description = "Id da competição") @PathVariable UUID competitionId,
            Authentication authentication) {
        service.deactivate(teamId, competitionId, authentication.getName());
    }

    @Operation(
            summary = "Reativar elenco do time na competição",
            description = "Marca o elenco (roster) de um time em uma competição como ACTIVE. "
                    + "Permitido apenas para ADMIN ou ORGANIZER."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é ADMIN nem ORGANIZER")
    @PostMapping("/api/v1/teams/{teamId}/competitions/{competitionId}/roster/reactivate")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void reactivate(
            @Parameter(description = "Id do time") @PathVariable UUID teamId,
            @Parameter(description = "Id da competição") @PathVariable UUID competitionId,
            Authentication authentication) {
        service.reactivate(teamId, competitionId, authentication.getName());
    }

}
