package br.com.flagplatform.team.controller;

import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.team.dto.request.CreateTeamRequest;
import br.com.flagplatform.team.dto.request.EnrollTeamRequest;
import br.com.flagplatform.team.dto.request.UpdateTeamRequest;
import br.com.flagplatform.team.dto.response.CompetitionTeamResponse;
import br.com.flagplatform.team.dto.response.TeamResponse;
import br.com.flagplatform.team.service.TeamService;
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
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Teams", description = "Endpoints para criar e gerenciar times")
@RestController
@RequiredArgsConstructor
public class TeamController {

    private final TeamService service;

    // --- Team CRUD (sub-entity of Organization) ---

    @Operation(
            summary = "Criar time",
            description = "Cria um time dentro de um clube (organização). Permitido apenas para ADMIN ou ORGANIZER."
    )
    @PostMapping("/api/v1/organizations/{organizationId}/teams")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public TeamResponse create(
            @Parameter(description = "Id da organização (clube)") @PathVariable UUID organizationId,
            @Valid @RequestBody CreateTeamRequest request,
            Authentication authentication) {
        return service.create(organizationId, request, authentication.getName());
    }

    @Operation(
            summary = "Listar times de um clube",
            description = "Lista os times de uma organização (clube), ordenados por nome. Acesso público."
    )
    @GetMapping("/api/v1/organizations/{organizationId}/teams")
    public List<TeamResponse> findByOrganizationId(
            @Parameter(description = "Id da organização") @PathVariable UUID organizationId) {
        return service.findByOrganizationId(organizationId);
    }

    @Operation(
            summary = "Listar todos os times",
            description = "Lista todos os times da plataforma. Usado pelas telas de associação de times a campeonatos. Acesso público."
    )
    @GetMapping("/api/v1/teams")
    public List<TeamResponse> findAll() {
        return service.findAll();
    }

    @Operation(
            summary = "Buscar time por id",
            description = "Retorna o detalhe de um time. Acesso público."
    )
    @GetMapping("/api/v1/teams/{id}")
    public TeamResponse findById(
            @Parameter(description = "Id do time") @PathVariable UUID id) {
        return service.findById(id);
    }

    @Operation(
            summary = "Atualizar time",
            description = "Atualiza um time existente. Permitido apenas para ADMIN ou ORGANIZER."
    )
    @PutMapping("/api/v1/teams/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public TeamResponse update(
            @Parameter(description = "Id do time") @PathVariable UUID id,
            @Valid @RequestBody UpdateTeamRequest request,
            Authentication authentication) {
        return service.update(id, request, authentication.getName());
    }

    @Operation(
            summary = "Excluir time",
            description = "Remove um time. Permitido apenas para ADMIN ou ORGANIZER."
    )
    @DeleteMapping("/api/v1/teams/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void delete(
            @Parameter(description = "Id do time") @PathVariable UUID id,
            Authentication authentication) {
        service.delete(id, authentication.getName());
    }

    @Operation(
            summary = "Desativar time",
            description = "Exclusão lógica: marca o time como INACTIVE. Permitido apenas para ADMIN ou ORGANIZER."
    )
    @PostMapping("/api/v1/teams/{id}/deactivate")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void deactivate(
            @Parameter(description = "Id do time") @PathVariable UUID id,
            Authentication authentication) {
        service.deactivate(id, authentication.getName());
    }

    @Operation(
            summary = "Reativar time",
            description = "Reverte a desativação lógica, voltando o time para ACTIVE. Permitido apenas para ADMIN ou ORGANIZER."
    )
    @PostMapping("/api/v1/teams/{id}/reactivate")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void reactivate(
            @Parameter(description = "Id do time") @PathVariable UUID id,
            Authentication authentication) {
        service.reactivate(id, authentication.getName());
    }

    // --- CompetitionTeam endpoints ---

    @Operation(
            summary = "Inscrever time em competição",
            description = "Inscreve um time em uma competição. Permitido apenas para ADMIN ou ORGANIZER."
    )
    @PostMapping("/api/v1/competitions/{competitionId}/teams/{teamId}")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public CompetitionTeamResponse enrollInCompetition(
            @Parameter(description = "Id da competição") @PathVariable UUID competitionId,
            @Parameter(description = "Id do time") @PathVariable UUID teamId,
            @RequestBody(required = false) EnrollTeamRequest request,
            Authentication authentication) {
        return service.enrollInCompetition(competitionId, teamId, request, authentication.getName());
    }

    @Operation(
            summary = "Listar times inscritos na competição",
            description = "Lista os times inscritos em uma competição. Acesso público."
    )
    @GetMapping("/api/v1/competitions/{competitionId}/teams")
    public List<CompetitionTeamResponse> findByCompetitionId(
            @Parameter(description = "Id da competição") @PathVariable UUID competitionId) {
        return service.findByCompetitionId(competitionId);
    }

    @Operation(
            summary = "Remover time da competição",
            description = "Remove a inscrição de um time em uma competição. Permitido apenas para ADMIN ou ORGANIZER."
    )
    @DeleteMapping("/api/v1/competitions/{competitionId}/teams/{teamId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void removeFromCompetition(
            @Parameter(description = "Id da competição") @PathVariable UUID competitionId,
            @Parameter(description = "Id do time") @PathVariable UUID teamId,
            Authentication authentication) {
        service.removeFromCompetition(competitionId, teamId);
    }

}
