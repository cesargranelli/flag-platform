package br.com.flagplatform.round.controller;

import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.round.dto.request.CreateRoundRequest;
import br.com.flagplatform.round.dto.request.UpdateRoundRequest;
import br.com.flagplatform.round.dto.response.RoundResponse;
import br.com.flagplatform.round.service.RoundService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Rounds", description = "Endpoints para criar e gerenciar rodadas")
@RestController
@RequiredArgsConstructor
public class RoundController {

    private final RoundService service;

    @Operation(
            summary = "Criar rodada",
            description = "Cria uma nova rodada em um campeonato. Permitido apenas ao criador do campeonato ou ADMIN."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @PostMapping("/api/v1/rounds")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public RoundResponse create(@Valid @RequestBody CreateRoundRequest request, Authentication authentication) {
        return service.create(request, authentication.getName());
    }

    @Operation(
            summary = "Listar rodadas por campeonato",
            description = "Lista as rodadas de um campeonato, ordenadas por número. Acesso público."
    )
    @GetMapping("/api/v1/competitions/{competitionId}/rounds")
    public List<RoundResponse> findByCompetitionId(
            @Parameter(description = "Id do campeonato") @PathVariable UUID competitionId) {
        return service.findByCompetitionId(competitionId);
    }

    @Operation(
            summary = "Obter rodada",
            description = "Retorna o detalhe de uma rodada. Acesso público."
    )
    @GetMapping("/api/v1/rounds/{id}")
    public RoundResponse findById(
            @Parameter(description = "Id da rodada") @PathVariable UUID id) {
        return service.findById(id);
    }

    @Operation(
            summary = "Atualizar rodada",
            description = "Atualiza uma rodada existente. Permitido apenas ao criador do campeonato ou ADMIN."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @PutMapping("/api/v1/rounds/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public RoundResponse update(
            @Parameter(description = "Id da rodada") @PathVariable UUID id,
            @Valid @RequestBody UpdateRoundRequest request,
            Authentication authentication) {
        return service.update(id, request, authentication.getName());
    }

}
