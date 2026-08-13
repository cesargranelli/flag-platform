package br.com.flagplatform.round.controller;

import br.com.flagplatform.round.dto.request.CreateRoundRequest;
import br.com.flagplatform.round.dto.request.UpdateRoundRequest;
import br.com.flagplatform.round.dto.response.RoundResponse;
import br.com.flagplatform.round.service.RoundService;
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

@Tag(name = "Rounds", description = "Endpoints para criar e gerenciar rodadas")
@RestController
@RequiredArgsConstructor
public class RoundController {

    private final RoundService service;

    @Operation(
            summary = "Criar rodada",
            description = "Cria uma nova rodada em uma categoria. Requer autenticação."
    )
    @PostMapping("/api/v1/rounds")
    @ResponseStatus(HttpStatus.CREATED)
    public RoundResponse create(@Valid @RequestBody CreateRoundRequest request) {
        return service.create(request);
    }

    @Operation(
            summary = "Listar rodadas por categoria",
            description = "Lista as rodadas de uma categoria, ordenadas por número. Acesso público."
    )
    @GetMapping("/api/v1/categories/{categoryId}/rounds")
    public List<RoundResponse> findByCategoryId(
            @Parameter(description = "Id da categoria") @PathVariable UUID categoryId) {
        return service.findByCategoryId(categoryId);
    }

    @Operation(
            summary = "Atualizar rodada",
            description = "Atualiza uma rodada existente. Requer autenticação."
    )
    @PutMapping("/api/v1/rounds/{id}")
    public RoundResponse update(
            @Parameter(description = "Id da rodada") @PathVariable UUID id,
            @Valid @RequestBody UpdateRoundRequest request) {
        return service.update(id, request);
    }

}
