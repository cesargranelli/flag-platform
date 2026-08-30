package br.com.flagplatform.play.controller;

import br.com.flagplatform.play.dto.request.CreatePlayRequest;
import br.com.flagplatform.play.dto.response.PlayResponse;
import br.com.flagplatform.play.service.PlayService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

import static br.com.flagplatform.common.security.SecurityExpressions.ADMIN_OR_MESA;

@Tag(name = "Plays", description = "Endpoints para play-by-play de jogos")
@RestController
@RequestMapping("/api/v1/games/{gameId}/plays")
@RequiredArgsConstructor
public class PlayController {

    private final PlayService service;

    @Operation(
            summary = "Listar lances de um jogo",
            description = "Retorna os lances (play-by-play) de um jogo, ordenados do mais recente ao mais antigo. Acesso público."
    )
    @GetMapping
    public List<PlayResponse> findByGameId(
            @Parameter(description = "Id do jogo") @PathVariable UUID gameId) {
        return service.findByGameId(gameId);
    }

    @Operation(
            summary = "Registrar lance",
            description = "Registra um novo lance (play) em um jogo em andamento. Requer autenticação."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não autenticado ou sem permissão")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(ADMIN_OR_MESA)
    public PlayResponse create(
            @Parameter(description = "Id do jogo") @PathVariable UUID gameId,
            @Valid @RequestBody CreatePlayRequest request) {
        return service.create(gameId, request);
    }

}
