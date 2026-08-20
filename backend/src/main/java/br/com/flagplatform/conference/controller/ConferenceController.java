package br.com.flagplatform.conference.controller;

import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.conference.dto.request.CreateConferenceRequest;
import br.com.flagplatform.conference.dto.request.UpdateConferenceRequest;
import br.com.flagplatform.conference.dto.response.ConferenceResponse;
import br.com.flagplatform.conference.service.ConferenceService;
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

@Tag(name = "Conferences", description = "Endpoints para criar e gerenciar conferências")
@RestController
@RequiredArgsConstructor
public class ConferenceController {

    private final ConferenceService service;

    @Operation(
            summary = "Criar conferência",
            description = "Cria uma conferência dentro de uma categoria. Requer autenticação."
    )
    @PostMapping("/api/v1/categories/{categoryId}/conferences")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public ConferenceResponse create(
            @Parameter(description = "Id da categoria") @PathVariable UUID categoryId,
            @Valid @RequestBody CreateConferenceRequest request) {
        return service.create(categoryId, request);
    }

    @Operation(
            summary = "Listar conferências por categoria",
            description = "Lista as conferências de uma categoria, ordenadas por nome. Acesso público."
    )
    @GetMapping("/api/v1/categories/{categoryId}/conferences")
    public List<ConferenceResponse> findByCategoryId(
            @Parameter(description = "Id da categoria") @PathVariable UUID categoryId) {
        return service.findByCategoryId(categoryId);
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
            description = "Atualiza uma conferência existente. Requer autenticação."
    )
    @PutMapping("/api/v1/conferences/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public ConferenceResponse update(
            @Parameter(description = "Id da conferência") @PathVariable UUID id,
            @Valid @RequestBody UpdateConferenceRequest request) {
        return service.update(id, request);
    }

}