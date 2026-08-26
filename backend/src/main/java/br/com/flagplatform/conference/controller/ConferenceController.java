package br.com.flagplatform.conference.controller;

import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.conference.dto.request.CreateConferenceRequest;
import br.com.flagplatform.conference.dto.request.UpdateConferenceRequest;
import br.com.flagplatform.conference.dto.response.ConferenceResponse;
import br.com.flagplatform.conference.service.ConferenceService;
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
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Conferences", description = "Endpoints para criar e gerenciar conferências")
@RestController
@RequiredArgsConstructor
public class ConferenceController {

    private final ConferenceService service;

    @Operation(
            summary = "Criar conferência",
            description = "Cria uma conferência dentro de um campeonato. Permitido apenas ao criador do campeonato ou ADMIN."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @PostMapping("/api/v1/competitions/{competitionId}/conferences")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public ConferenceResponse create(
            @Parameter(description = "Id do campeonato") @PathVariable UUID competitionId,
            @Valid @RequestBody CreateConferenceRequest request,
            Authentication authentication) {
        return service.create(competitionId, request, authentication.getName());
    }

    @Operation(
            summary = "Listar conferências por campeonato",
            description = "Lista as conferências de um campeonato, ordenadas por nome. Acesso público."
    )
    @GetMapping("/api/v1/competitions/{competitionId}/conferences")
    public List<ConferenceResponse> findByCompetitionId(
            @Parameter(description = "Id do campeonato") @PathVariable UUID competitionId) {
        return service.findByCompetitionId(competitionId);
    }

    @Operation(
            summary = "Buscar conferência por id",
            description = "Retorna o detalhe de uma conferência. Acesso público."
    )
    @GetMapping("/api/v1/conferences/{id}")
    public ConferenceResponse findById(
            @Parameter(description = "Id da conferência") @PathVariable UUID id) {
        return service.findById(id);
    }

    @Operation(
            summary = "Atualizar conferência",
            description = "Atualiza uma conferência existente. Permitido apenas ao criador do campeonato ou ADMIN."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @PutMapping("/api/v1/conferences/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public ConferenceResponse update(
            @Parameter(description = "Id da conferência") @PathVariable UUID id,
            @Valid @RequestBody UpdateConferenceRequest request,
            Authentication authentication) {
        return service.update(id, request, authentication.getName());
    }

    @Operation(
            summary = "Excluir conferência",
            description = "Remove uma conferência e suas divisões vinculadas. Permitido apenas ao criador " +
                    "do campeonato ou ADMIN, enquanto estiver em status DRAFT."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @DeleteMapping("/api/v1/conferences/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void delete(
            @Parameter(description = "Id da conferência") @PathVariable UUID id,
            Authentication authentication) {
        service.delete(id, authentication.getName());
    }

}