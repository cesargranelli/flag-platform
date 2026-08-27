package br.com.flagplatform.team.controller;

import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.team.dto.request.CreateTeamRequest;
import br.com.flagplatform.team.dto.request.UpdateTeamRequest;
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

    @Operation(
            summary = "Criar time",
            description = "Cria a inscrição de uma organização (clube) no campeonato. Permitido apenas ao criador do campeonato ou ADMIN."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @PostMapping("/api/v1/teams")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public TeamResponse create(@Valid @RequestBody CreateTeamRequest request, Authentication authentication) {
        return service.create(request, authentication.getName());
    }

    @Operation(
            summary = "Listar times por campeonato",
            description = "Lista os times inscritos em um campeonato, ordenados por nome. Acesso público."
    )
    @GetMapping("/api/v1/competitions/{competitionId}/teams")
    public List<TeamResponse> findByCompetitionId(
            @Parameter(description = "Id do campeonato") @PathVariable UUID competitionId) {
        return service.findByCompetitionId(competitionId);
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
            description = "Atualiza um time existente. Permitido apenas ao criador do campeonato ou ADMIN."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @PutMapping("/api/v1/teams/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public TeamResponse update(
            @Parameter(description = "Id do time") @PathVariable UUID id,
            @Valid @RequestBody UpdateTeamRequest request,
            Authentication authentication) {
        return service.update(id, request, authentication.getName());
    }

    @Operation(
            summary = "Excluir time (desassociar clube)",
            description = "Remove a inscri��ǜo do clube no campeonato. Permitido apenas ao criador do campeonato ou ADMIN, enquanto estiver em DRAFT."
    )
    @ApiResponse(responseCode = "403", description = "Usuǭrio nǜo Ǹ o criador do campeonato nem ADMIN")
    @ApiResponse(responseCode = "409", description = "O clube jǭ possui jogos associados")
    @DeleteMapping("/api/v1/teams/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void delete(
            @Parameter(description = "Id do time") @PathVariable UUID id,
            Authentication authentication) {
        service.delete(id, authentication.getName());
    }

}
