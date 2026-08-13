package br.com.flagplatform.competition.controller;

import br.com.flagplatform.competition.dto.request.CreateCompetitionRequest;
import br.com.flagplatform.competition.dto.request.UpdateCompetitionRequest;
import br.com.flagplatform.competition.dto.response.CompetitionResponse;
import br.com.flagplatform.competition.dto.response.CompetitionSummaryResponse;
import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.competition.service.CompetitionService;
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

@Tag(name = "Competitions", description = "Endpoints para criar e gerenciar campeonatos")
@RestController
@RequiredArgsConstructor
public class CompetitionController {

    private final CompetitionService service;

    @Operation(
            summary = "Criar campeonato",
            description = "Cria um novo campeonato. Requer autenticação."
    )
    @PostMapping("/api/v1/competitions")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public CompetitionResponse create(@Valid @RequestBody CreateCompetitionRequest request) {
        return service.create(request);
    }

    @Operation(
            summary = "Listar campeonatos",
            description = "Lista todos os campeonatos, com nome da organização. Acesso público."
    )
    @GetMapping("/api/v1/competitions")
    public List<CompetitionSummaryResponse> listAll() {
        return service.listAllPublic();
    }

    @Operation(
            summary = "Buscar campeonato por id",
            description = "Retorna o detalhe de um campeonato. Acesso público."
    )
    @GetMapping("/api/v1/competitions/{id}")
    public CompetitionResponse getById(
            @Parameter(description = "Id do campeonato") @PathVariable UUID id) {
        return service.findById(id);
    }

    @Operation(
            summary = "Listar campeonatos por organização",
            description = "Lista os campeonatos de uma organização, ordenados por nome. Acesso público."
    )
    @GetMapping("/api/v1/organizations/{organizationId}/competitions")
    public List<CompetitionResponse> findByOrganizationId(
            @Parameter(description = "Id da organização") @PathVariable UUID organizationId) {
        return service.findByOrganizationId(organizationId);
    }

    @Operation(
            summary = "Atualizar campeonato",
            description = "Atualiza um campeonato existente. Requer autenticação."
    )
    @PutMapping("/api/v1/competitions/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public CompetitionResponse update(
            @Parameter(description = "Id do campeonato") @PathVariable UUID id,
            @Valid @RequestBody UpdateCompetitionRequest request) {
        return service.update(id, request);
    }

}
