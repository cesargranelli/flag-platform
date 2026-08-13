package br.com.flagplatform.game.controller;

import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.game.dto.request.CreateGameRequest;
import br.com.flagplatform.game.dto.request.RegisterGameResultRequest;
import br.com.flagplatform.game.dto.request.UpdateGameRequest;
import br.com.flagplatform.game.dto.request.UpdateGameStatusRequest;
import br.com.flagplatform.game.dto.response.GameResponse;
import br.com.flagplatform.game.dto.response.GameSummaryResponse;
import br.com.flagplatform.game.service.GameService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Games", description = "Endpoints para criar e gerenciar jogos")
@RestController
@RequiredArgsConstructor
public class GameController {

    private final GameService service;

    @Operation(
            summary = "Criar jogo",
            description = "Cria um novo jogo em uma rodada. Requer autenticação."
    )
    @PostMapping("/api/v1/games")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public GameResponse create(@Valid @RequestBody CreateGameRequest request) {
        return service.create(request);
    }

    @Operation(
            summary = "Listar jogos por rodada",
            description = "Lista os jogos de uma rodada, ordenados por horário. Acesso público."
    )
    @GetMapping("/api/v1/rounds/{roundId}/games")
    public List<GameResponse> findByRoundId(
            @Parameter(description = "Id da rodada") @PathVariable UUID roundId) {
        return service.findByRoundId(roundId);
    }

    @Operation(
            summary = "Listar jogos por competição",
            description = "Lista os jogos de uma competição (todas as categorias), ordenados por data, com nomes de times e campo. Acesso público."
    )
    @GetMapping("/api/v1/competitions/{competitionId}/games")
    public List<GameSummaryResponse> findByCompetitionId(
            @Parameter(description = "Id da competição") @PathVariable UUID competitionId) {
        return service.findByCompetitionId(competitionId);
    }

    @Operation(
            summary = "Buscar jogo por id",
            description = "Retorna o detalhe de um jogo. Acesso público."
    )
    @GetMapping("/api/v1/games/{id}")
    public GameResponse findById(
            @Parameter(description = "Id do jogo") @PathVariable UUID id) {
        return service.findById(id);
    }

    @Operation(
            summary = "Atualizar jogo",
            description = "Atualiza horário ou campo de um jogo existente. Requer autenticação."
    )
    @PutMapping("/api/v1/games/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public GameResponse update(
            @Parameter(description = "Id do jogo") @PathVariable UUID id,
            @Valid @RequestBody UpdateGameRequest request) {
        return service.update(id, request);
    }

    @Operation(
            summary = "Atualizar status do jogo",
            description = "Atualiza o status de um jogo conforme as transições válidas (SCHEDULED->IN_PROGRESS, IN_PROGRESS->FINISHED, SCHEDULED->CANCELLED). Requer autenticação."
    )
    @PatchMapping("/api/v1/games/{id}/status")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_MESA)
    public GameResponse updateStatus(
            @Parameter(description = "Id do jogo") @PathVariable UUID id,
            @Valid @RequestBody UpdateGameStatusRequest request) {
        return service.updateStatus(id, request.status());
    }

    @Operation(
            summary = "Registrar resultado de partida",
            description = "Registra o placar final de um jogo em andamento, finaliza o jogo (FINISHED) e recalcula a classificacao da categoria automaticamente. Requer autenticacao."
    )
    @PostMapping("/api/v1/games/{id}/result")
    @ResponseStatus(HttpStatus.OK)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_MESA)
    public GameResponse registerResult(
            @Parameter(description = "Id do jogo") @PathVariable UUID id,
            @Valid @RequestBody RegisterGameResultRequest request) {
        return service.registerResult(id, request);
    }

}
