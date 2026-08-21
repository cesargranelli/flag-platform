package br.com.flagplatform.division.controller;

import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.division.dto.request.CreateDivisionRequest;
import br.com.flagplatform.division.dto.request.UpdateDivisionRequest;
import br.com.flagplatform.division.dto.response.DivisionResponse;
import br.com.flagplatform.division.service.DivisionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Divisions", description = "Endpoints para criar e gerenciar divisões")
@RestController
@RequiredArgsConstructor
public class DivisionController {

    private final DivisionService service;

    @Operation(
            summary = "Criar divisão",
            description = "Cria uma divisão dentro de um campeonato, opcionalmente " +
                    "vinculada a uma conferência. Requer autenticação."
    )
    @PostMapping("/api/v1/competitions/{competitionId}/divisions")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public DivisionResponse create(
            @Parameter(description = "Id do campeonato") @PathVariable UUID competitionId,
            @Valid @RequestBody CreateDivisionRequest request) {
        return service.create(competitionId, request);
    }

    @Operation(
            summary = "Listar divisões por campeonato",
            description = "Lista as divisões de um campeonato, ordenadas por nome. Acesso público."
    )
    @GetMapping("/api/v1/competitions/{competitionId}/divisions")
    public List<DivisionResponse> findByCompetitionId(
            @Parameter(description = "Id do campeonato") @PathVariable UUID competitionId) {
        return service.findByCompetitionId(competitionId);
    }

    @Operation(
            summary = "Buscar divisão por id",
            description = "Retorna o detalhe de uma divisão. Acesso público."
    )
    @GetMapping("/api/v1/divisions/{id}")
    public DivisionResponse findById(
            @Parameter(description = "Id da divisão") @PathVariable UUID id) {
        return service.findById(id);
    }

    @Operation(
            summary = "Atualizar divisão",
            description = "Atualiza uma divisão existente. Requer autenticação."
    )
    @PutMapping("/api/v1/divisions/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public DivisionResponse update(
            @Parameter(description = "Id da divisão") @PathVariable UUID id,
            @Valid @RequestBody UpdateDivisionRequest request) {
        return service.update(id, request);
    }

}