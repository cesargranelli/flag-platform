package br.com.flagplatform.athlete.controller;

import br.com.flagplatform.athlete.dto.request.CreateAthleteRequest;
import br.com.flagplatform.athlete.dto.request.UpdateAthleteRequest;
import br.com.flagplatform.athlete.dto.response.AthleteResponse;
import br.com.flagplatform.athlete.service.AthleteService;
import br.com.flagplatform.common.security.SecurityExpressions;
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

@Tag(name = "Athletes", description = "Endpoints para criar e gerenciar atletas")
@RestController
@RequiredArgsConstructor
public class AthleteController {

    private final AthleteService service;

    @Operation(
            summary = "Criar atleta",
            description = "Cria um novo atleta. Requer autenticação."
    )
    @PostMapping("/api/v1/athletes")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public AthleteResponse create(@Valid @RequestBody CreateAthleteRequest request) {
        return service.create(request);
    }

    @Operation(
            summary = "Listar atletas",
            description = "Lista todos os atletas, ordenados por nome. Acesso público."
    )
    @GetMapping("/api/v1/athletes")
    public List<AthleteResponse> findAll() {
        return service.findAll();
    }

    @Operation(
            summary = "Buscar atleta por id",
            description = "Retorna o detalhe de um atleta. Acesso público."
    )
    @GetMapping("/api/v1/athletes/{id}")
    public AthleteResponse findById(
            @Parameter(description = "Id do atleta") @PathVariable UUID id) {
        return service.findById(id);
    }

    @Operation(
            summary = "Atualizar atleta",
            description = "Atualiza um atleta existente. Requer autenticação."
    )
    @PutMapping("/api/v1/athletes/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public AthleteResponse update(
            @Parameter(description = "Id do atleta") @PathVariable UUID id,
            @Valid @RequestBody UpdateAthleteRequest request) {
        return service.update(id, request);
    }

}
