package br.com.flagplatform.game.controller;

import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.game.dto.request.AddScoreEventRequest;
import br.com.flagplatform.game.dto.request.CreateGameRequest;
import br.com.flagplatform.game.dto.request.GameBatchRequest;
import br.com.flagplatform.game.dto.request.RegisterGameResultRequest;
import br.com.flagplatform.game.dto.request.UpdateGameRequest;
import br.com.flagplatform.game.dto.request.UpdateGameStatusRequest;
import br.com.flagplatform.game.dto.request.UpdateScoreRequest;
import br.com.flagplatform.game.dto.response.GameResponse;
import br.com.flagplatform.game.dto.response.GameBatchResponse;
import br.com.flagplatform.game.dto.response.GameSummaryResponse;
import br.com.flagplatform.game.dto.response.LiveGameResponse;
import br.com.flagplatform.game.dto.response.ScoreEventResponse;
import br.com.flagplatform.game.service.GameService;
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
            summary = "Listar jogos ao vivo",
            description = "Retorna jogos IN_PROGRESS e finalizados nas últimas 24h, com metadados da competição (modalidade, gênero). Acesso público."
    )
    @GetMapping("/api/v1/games/live")
    public List<LiveGameResponse> findLiveGames() {
        return service.findLiveGames();
    }

    @Operation(
            summary = "Criar jogo",
            description = "Cria um novo jogo em uma rodada. Permitido apenas ao criador do campeonato ou ADMIN."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @PostMapping("/api/v1/games")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public GameResponse create(@Valid @RequestBody CreateGameRequest request, Authentication authentication) {
        return service.create(request, authentication.getName());
    }

    @Operation(
            summary = "Importar jogos em lote",
            description = "Cria varios jogos de uma rodada de uma vez. Linhas invalidas/duplicadas nao abortam as validas. Permitido apenas ao criador do campeonato ou ADMIN."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @PostMapping("/api/v1/rounds/{roundId}/games/batch")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public GameBatchResponse createBatch(
            @Parameter(description = "Id da rodada") @PathVariable UUID roundId,
            @Valid @RequestBody GameBatchRequest request,
            Authentication authentication) {
        return service.createBatch(roundId, request, authentication.getName());
    }

    @Operation(
            summary = "Listar jogos por rodada",
            description = "Lista os jogos de uma rodada, ordenados por horário, com nomes de times e campo. Acesso público."
    )
    @GetMapping("/api/v1/rounds/{roundId}/games")
    public List<GameSummaryResponse> findByRoundId(
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
            description = "Atualiza horário, campo ou rodada de um jogo existente. Permitido apenas ao criador do campeonato ou ADMIN."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @PutMapping("/api/v1/games/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public GameResponse update(
            @Parameter(description = "Id do jogo") @PathVariable UUID id,
            @Valid @RequestBody UpdateGameRequest request,
            Authentication authentication) {
        return service.update(id, request, authentication.getName());
    }

    @Operation(
            summary = "Atualizar status do jogo",
            description = "Atualiza o status de um jogo conforme as transições válidas (SCHEDULED->OPEN, OPEN->IN_PROGRESS, IN_PROGRESS->CONFERENCE, CONFERENCE->FINISHED, SCHEDULED/OPEN->CANCELLED). Requer autenticação."
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
            description = "Registra o placar final de um jogo em conferência (CONFERENCE), finaliza o jogo (FINISHED) e recalcula a classificacao da categoria automaticamente. Requer autenticacao."
    )
    @PostMapping("/api/v1/games/{id}/result")
    @ResponseStatus(HttpStatus.OK)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_MESA)
    public GameResponse registerResult(
            @Parameter(description = "Id do jogo") @PathVariable UUID id,
            @Valid @RequestBody RegisterGameResultRequest request) {
        return service.registerResult(id, request);
    }

    @Operation(
            summary = "Adicionar ponto ao placar",
            description = "Adiciona 1 ponto ao time informado durante a partida (IN_PROGRESS) e registra o evento. Requer autenticacao."
    )
    @PostMapping("/api/v1/games/{id}/score/events")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_MESA)
    public GameResponse addScoreEvent(
            @Parameter(description = "Id do jogo") @PathVariable UUID id,
            @Valid @RequestBody AddScoreEventRequest request) {
        return service.registerScoreEvent(id, request);
    }

    @Operation(
            summary = "Corrigir placar",
            description = "Define os pontos de casa e fora durante a partida (IN_PROGRESS). Requer autenticacao."
    )
    @PatchMapping("/api/v1/games/{id}/score")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_MESA)
    public GameResponse correctScore(
            @Parameter(description = "Id do jogo") @PathVariable UUID id,
            @Valid @RequestBody UpdateScoreRequest request) {
        return service.correctScore(id, request);
    }

    @Operation(
            summary = "Historico de pontuacao",
            description = "Retorna os eventos de pontuacao de um jogo, ordenados por data. Acesso publico."
    )
    @GetMapping("/api/v1/games/{id}/score/events")
    public List<ScoreEventResponse> listScoreEvents(
            @Parameter(description = "Id do jogo") @PathVariable UUID id) {
        return service.listScoreEvents(id);
    }

}
