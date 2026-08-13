package br.com.flagplatform.team.controller;

import br.com.flagplatform.team.dto.request.CreateTeamRequest;
import br.com.flagplatform.team.dto.request.UpdateTeamRequest;
import br.com.flagplatform.team.dto.response.TeamResponse;
import br.com.flagplatform.team.service.TeamService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
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
            description = "Cria um novo time em uma categoria. Requer autenticação."
    )
    @PostMapping("/api/v1/teams")
    @ResponseStatus(HttpStatus.CREATED)
    public TeamResponse create(@Valid @RequestBody CreateTeamRequest request) {
        return service.create(request);
    }

    @Operation(
            summary = "Listar times por categoria",
            description = "Lista os times de uma categoria, ordenados por nome. Acesso público."
    )
    @GetMapping("/api/v1/categories/{categoryId}/teams")
    public List<TeamResponse> findByCategoryId(
            @Parameter(description = "Id da categoria") @PathVariable UUID categoryId) {
        return service.findByCategoryId(categoryId);
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
            description = "Atualiza um time existente. Requer autenticação."
    )
    @PutMapping("/api/v1/teams/{id}")
    public TeamResponse update(
            @Parameter(description = "Id do time") @PathVariable UUID id,
            @Valid @RequestBody UpdateTeamRequest request) {
        return service.update(id, request);
    }

}
