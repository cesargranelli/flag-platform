package br.com.flagplatform.venue.controller;

import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.venue.dto.request.CreateVenueRequest;
import br.com.flagplatform.venue.dto.request.UpdateVenueRequest;
import br.com.flagplatform.venue.dto.response.VenueResponse;
import br.com.flagplatform.venue.service.VenueService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Venues", description = "Endpoints para criar e gerenciar campos de jogo")
@RestController
@RequiredArgsConstructor
public class VenueController {

    private final VenueService service;

    @Operation(
            summary = "Criar campo de jogo",
            description = "Cria um novo campo de jogo. Requer autenticação."
    )
    @PostMapping("/api/v1/venues")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public VenueResponse create(@Valid @RequestBody CreateVenueRequest request) {
        return service.create(request);
    }

    @Operation(
            summary = "Listar campos de jogo",
            description = "Lista todos os campos de jogo, ordenados por nome. Acesso público."
    )
    @GetMapping("/api/v1/venues")
    public List<VenueResponse> findAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size,
            HttpServletResponse response) {
        var result = service.findAll(page, size);
        response.setHeader("X-Total-Count", String.valueOf(result.total()));
        return result.items();
    }

    @Operation(
            summary = "Buscar campo de jogo por id",
            description = "Retorna o detalhe de um campo de jogo. Acesso público."
    )
    @GetMapping("/api/v1/venues/{id}")
    public VenueResponse findById(
            @Parameter(description = "Id do campo de jogo") @PathVariable UUID id) {
        return service.findById(id);
    }

    @Operation(
            summary = "Atualizar campo de jogo",
            description = "Atualiza um campo de jogo existente. Requer autenticação."
    )
    @PutMapping("/api/v1/venues/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public VenueResponse update(
            @Parameter(description = "Id do campo de jogo") @PathVariable UUID id,
            @Valid @RequestBody UpdateVenueRequest request) {
        return service.update(id, request);
    }

}
