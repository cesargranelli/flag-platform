package br.com.flagplatform.game.service;

import br.com.flagplatform.common.enums.GameStatus;
import br.com.flagplatform.competition.CompetitionInfo;
import br.com.flagplatform.competition.CompetitionLookup;
import br.com.flagplatform.game.FinishedGame;
import br.com.flagplatform.game.GameInfo;
import br.com.flagplatform.game.GameLookup;
import br.com.flagplatform.game.GameResultRegisteredEvent;
import br.com.flagplatform.game.dto.request.AddScoreEventRequest;
import br.com.flagplatform.game.dto.request.CreateGameRequest;
import br.com.flagplatform.game.dto.request.GameBatchItem;
import br.com.flagplatform.game.dto.request.GameBatchRequest;
import br.com.flagplatform.game.dto.request.RegisterGameResultRequest;
import br.com.flagplatform.game.dto.request.UpdateGameRequest;
import br.com.flagplatform.game.dto.request.UpdateGameStatusRequest;
import br.com.flagplatform.game.dto.request.UpdateScoreRequest;
import br.com.flagplatform.game.dto.response.GameResponse;
import br.com.flagplatform.game.dto.response.GameBatchLineResult;
import br.com.flagplatform.game.dto.response.GameBatchResponse;
import br.com.flagplatform.game.dto.response.GameSummaryResponse;
import br.com.flagplatform.game.dto.response.LiveGameResponse;
import br.com.flagplatform.game.dto.response.ScoreEventResponse;
import br.com.flagplatform.game.entity.GameEntity;
import br.com.flagplatform.game.entity.ScoreEventEntity;
import br.com.flagplatform.game.exception.GameNotFoundException;
import br.com.flagplatform.game.exception.GameNotInProgressException;
import br.com.flagplatform.game.exception.InvalidGameStatusTransitionException;
import br.com.flagplatform.game.exception.SameTeamGameException;
import br.com.flagplatform.game.exception.TeamNotInGameException;
import br.com.flagplatform.game.mapper.GameMapper;
import br.com.flagplatform.game.repository.GameRepository;
import br.com.flagplatform.game.repository.ScoreEventRepository;
import br.com.flagplatform.round.RoundInfo;
import br.com.flagplatform.round.RoundLookup;
import br.com.flagplatform.team.TeamLookup;
import br.com.flagplatform.venue.VenueInfo;
import br.com.flagplatform.venue.VenueLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class GameService implements GameLookup {

    private final GameMapper mapper;
    private final GameRepository repository;
    private final ScoreEventRepository scoreEventRepository;
    private final CompetitionLookup competitionLookup;
    private final RoundLookup roundLookup;
    private final VenueLookup venueLookup;
    private final TeamLookup teamLookup;
    private final ApplicationEventPublisher applicationEventPublisher;

    @Transactional
    public GameResponse create(CreateGameRequest request, String currentUserEmail) {
        // V260: apenas o criador do campeonato (ou ADMIN) gerencia o campeonato.
        competitionLookup.assertManagedBy(roundLookup.findCompetitionId(request.roundId()), currentUserEmail);

        validateReferences(request.roundId(), request.homeTeamId(), request.awayTeamId(), request.venueId());

        GameEntity entity = mapper.toEntity(request);
        if (entity.getStatus() == null) {
            entity.setStatus(GameStatus.SCHEDULED);
        }

        return mapper.toResponse(repository.save(entity));
    }

    /**
     * Cria varios jogos de uma rodada de uma vez. Processa por linha: linhas
     * com times inexistentes, time casa == fora ou duplicadas sao reportadas
     * sem abortar as demais.
     */
    @Transactional
    public GameBatchResponse createBatch(UUID roundId, GameBatchRequest request, String currentUserEmail) {
        // V260: apenas o criador do campeonato (ou ADMIN) gerencia o campeonato.
        competitionLookup.assertManagedBy(roundLookup.findCompetitionId(roundId), currentUserEmail);

        List<GameBatchLineResult> lines = new ArrayList<>();
        int imported = 0;
        for (int i = 0; i < request.games().size(); i++) {
            GameBatchItem item = request.games().get(i);
            int line = i + 2; // linha 1 = cabecalho
            String error = validateBatchItem(item);
            if (error != null) {
                lines.add(new GameBatchLineResult(line, "INVALID", error, item));
                continue;
            }
            if (repository.existsByRoundIdAndHomeTeamIdAndAwayTeamId(
                    roundId, item.homeTeamId(), item.awayTeamId())) {
                lines.add(new GameBatchLineResult(
                        line, "SKIPPED", "Jogo já existe nesta rodada", item));
                continue;
            }
            GameEntity entity = new GameEntity();
            entity.setRoundId(roundId);
            entity.setHomeTeamId(item.homeTeamId());
            entity.setAwayTeamId(item.awayTeamId());
            entity.setVenueId(item.venueId());
            entity.setScheduledAt(item.scheduledAt());
            entity.setStatus(GameStatus.SCHEDULED);
            repository.save(entity);
            imported++;
            lines.add(new GameBatchLineResult(line, "IMPORTED", null, item));
        }
        return new GameBatchResponse(
                request.games().size(), imported, request.games().size() - imported, lines);
    }

    private String validateBatchItem(GameBatchItem item) {
        if (!teamLookup.existsById(item.homeTeamId())) {
            return "Time da casa não encontrado";
        }
        if (!teamLookup.existsById(item.awayTeamId())) {
            return "Time visitante não encontrado";
        }
        if (item.venueId() != null && !venueLookup.existsById(item.venueId())) {
            return "Campo não encontrado";
        }
        if (item.homeTeamId().equals(item.awayTeamId())) {
            return "Time da casa deve ser diferente do visitante";
        }
        return null;
    }

    public List<GameSummaryResponse> findByRoundId(UUID roundId) {
        int roundNumber = roundLookup.findRoundInfoById(roundId).number();

        return repository.findAllByRoundIdOrderByScheduledAtAsc(roundId).stream()
                .map(game -> {
                    VenueInfo venue = game.getVenueId() != null
                            ? venueLookup.findVenueInfoById(game.getVenueId())
                            : null;
                    return new GameSummaryResponse(
                            game.getId(),
                            game.getRoundId(),
                            roundNumber,
                            teamLookup.findTeamInfoById(game.getHomeTeamId()).name(),
                            teamLookup.findTeamInfoById(game.getAwayTeamId()).name(),
                            game.getVenueId(),
                            venue != null ? venue.name() : null,
                            venue != null ? venue.address() : null,
                            venue != null ? venue.mapsUrl() : null,
                            game.getScheduledAt(),
                            game.getStatus(),
                            game.getHomeScore(),
                            game.getAwayScore());
                })
                .toList();
    }

    public GameResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    public List<GameSummaryResponse> findByCompetitionId(UUID competitionId) {
        competitionLookup.assertExists(competitionId);

        List<RoundInfo> rounds = roundLookup.findRoundInfoByCompetitionId(competitionId);
        if (rounds.isEmpty()) {
            return List.of();
        }

        Map<UUID, Integer> roundNumbers = rounds.stream().collect(
                Collectors.toMap(RoundInfo::id, RoundInfo::number));
        List<UUID> roundIds = new ArrayList<>(roundNumbers.keySet());

        return repository.findAllByRoundIdInOrderByScheduledAtAsc(roundIds).stream()
                .map(game -> {
                    VenueInfo venue = game.getVenueId() != null
                            ? venueLookup.findVenueInfoById(game.getVenueId())
                            : null;
                    return new GameSummaryResponse(
                            game.getId(),
                            game.getRoundId(),
                            roundNumbers.get(game.getRoundId()),
                            teamLookup.findTeamInfoById(game.getHomeTeamId()).name(),
                            teamLookup.findTeamInfoById(game.getAwayTeamId()).name(),
                            game.getVenueId(),
                            venue != null ? venue.name() : null,
                            venue != null ? venue.address() : null,
                            venue != null ? venue.mapsUrl() : null,
                            game.getScheduledAt(),
                            game.getStatus(),
                            game.getHomeScore(),
                            game.getAwayScore());
                })
                .toList();
    }

    @Transactional
    public GameResponse update(UUID id, UpdateGameRequest request, String currentUserEmail) {
        GameEntity entity = findEntityById(id);

        // V260: valida o campeonato da rodada atual do jogo e, se houver mudança,
        // também o campeonato da nova rodada.
        competitionLookup.assertManagedBy(roundLookup.findCompetitionId(entity.getRoundId()), currentUserEmail);
        if (!entity.getRoundId().equals(request.roundId())) {
            competitionLookup.assertManagedBy(roundLookup.findCompetitionId(request.roundId()), currentUserEmail);
        }

        validateReferences(request.roundId(), request.homeTeamId(), request.awayTeamId(), request.venueId());

        mapper.updateEntity(entity, request);

        return mapper.toResponse(repository.save(entity));
    }

    @Transactional
    public GameResponse updateStatus(UUID id, GameStatus newStatus) {
        GameEntity entity = findEntityById(id);
        if (!isValidTransition(entity.getStatus(), newStatus)) {
            throw new InvalidGameStatusTransitionException(entity.getStatus(), newStatus);
        }

        entity.setStatus(newStatus);
        return mapper.toResponse(repository.save(entity));
    }

    @Transactional
    public GameResponse registerResult(UUID id, RegisterGameResultRequest request) {
        GameEntity entity = findEntityById(id);
        if (entity.getStatus() != GameStatus.CONFERENCE) {
            throw new GameNotInProgressException(entity.getStatus());
        }

        entity.setHomeScore(request.homeScore());
        entity.setAwayScore(request.awayScore());
        entity.setStatus(GameStatus.FINISHED);
        GameEntity saved = repository.save(entity);

        UUID competitionId = roundLookup.findCompetitionId(saved.getRoundId());
        applicationEventPublisher.publishEvent(new GameResultRegisteredEvent(saved.getId(), competitionId));

        return mapper.toResponse(saved);
    }

    @Override
    public List<FinishedGame> findFinishedByCompetitionId(UUID competitionId) {
        List<UUID> roundIds = roundLookup.findRoundIdsByCompetitionId(competitionId);
        if (roundIds.isEmpty()) {
            return List.of();
        }

        return repository.findAllByRoundIdInAndStatus(roundIds, GameStatus.FINISHED)
                .stream()
                .map(game -> new FinishedGame(
                        game.getHomeTeamId(),
                        game.getAwayTeamId(),
                        game.getHomeScore(),
                        game.getAwayScore()))
                .toList();
    }

    @Override
    public GameInfo findGameInfoById(UUID id) {
        GameEntity game = findEntityById(id);
        return new GameInfo(game.getId(), game.getHomeTeamId(), game.getAwayTeamId(), game.getStatus());
    }

    @Transactional
    public GameResponse registerScoreEvent(UUID gameId, AddScoreEventRequest request) {
        GameEntity game = findEntityById(gameId);
        requireInProgress(game);

        if (!game.getHomeTeamId().equals(request.teamId())
                && !game.getAwayTeamId().equals(request.teamId())) {
            throw new TeamNotInGameException(gameId, request.teamId());
        }

        if (game.getHomeTeamId().equals(request.teamId())) {
            game.setHomeScore((game.getHomeScore() == null ? 0 : game.getHomeScore()) + 1);
        } else {
            game.setAwayScore((game.getAwayScore() == null ? 0 : game.getAwayScore()) + 1);
        }

        ScoreEventEntity event = new ScoreEventEntity();
        event.setGameId(gameId);
        event.setTeamId(request.teamId());
        scoreEventRepository.save(event);

        return mapper.toResponse(repository.save(game));
    }

    @Transactional
    public GameResponse correctScore(UUID gameId, UpdateScoreRequest request) {
        GameEntity game = findEntityById(gameId);
        requireInProgress(game);

        game.setHomeScore(request.homeScore());
        game.setAwayScore(request.awayScore());

        return mapper.toResponse(repository.save(game));
    }

    public List<ScoreEventResponse> listScoreEvents(UUID gameId) {
        findEntityById(gameId);

        return scoreEventRepository.findAllByGameIdOrderByCreatedAtAsc(gameId).stream()
                .map(event -> new ScoreEventResponse(
                        event.getId(),
                        event.getGameId(),
                        event.getTeamId(),
                        event.getCreatedAt()))
                .toList();
    }

    public List<LiveGameResponse> findLiveGames() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime start = now.minusHours(24);

        List<GameStatus> statuses = List.of(GameStatus.IN_PROGRESS, GameStatus.FINISHED);

        List<GameEntity> games = repository.findLiveGames(statuses, start, now);
        if (games.isEmpty()) {
            return List.of();
        }

        // Batch resolve round → competitionId
        List<UUID> roundIds = games.stream().map(GameEntity::getRoundId).distinct().toList();
        Map<UUID, UUID> roundToCompetition = roundLookup.findCompetitionIdsByRoundIds(roundIds);

        // Batch resolve competition metadata
        List<UUID> competitionIds = roundToCompetition.values().stream().distinct().toList();
        Map<UUID, CompetitionInfo> competitionInfoMap = competitionLookup.findCompetitionInfoByIds(competitionIds);

        // Batch resolve round numbers
        Map<UUID, RoundInfo> roundInfoMap = roundLookup.findRoundInfoByIds(roundIds);

        return games.stream()
                .map(game -> {
                    VenueInfo venue = game.getVenueId() != null
                            ? venueLookup.findVenueInfoById(game.getVenueId())
                            : null;
                    UUID competitionId = roundToCompetition.get(game.getRoundId());
                    CompetitionInfo comp = competitionId != null ? competitionInfoMap.get(competitionId) : null;
                    RoundInfo roundInfo = roundInfoMap.get(game.getRoundId());

                    return new LiveGameResponse(
                            game.getId(),
                            game.getRoundId(),
                            roundInfo != null ? roundInfo.number() : null,
                            teamLookup.findTeamInfoById(game.getHomeTeamId()).name(),
                            teamLookup.findTeamInfoById(game.getAwayTeamId()).name(),
                            game.getVenueId(),
                            venue != null ? venue.name() : null,
                            venue != null ? venue.address() : null,
                            venue != null ? venue.mapsUrl() : null,
                            game.getScheduledAt(),
                            game.getStatus(),
                            game.getHomeScore(),
                            game.getAwayScore(),
                            competitionId,
                            comp != null ? comp.name() : null,
                            comp != null ? comp.modality() : null,
                            comp != null ? comp.gender() : null);
                })
                .toList();
    }

    private void requireInProgress(GameEntity game) {
        if (game.getStatus() != GameStatus.IN_PROGRESS) {
            throw new GameNotInProgressException(game.getStatus());
        }
    }

    private boolean isValidTransition(GameStatus current, GameStatus requested) {
        return switch (current) {
            case SCHEDULED -> requested == GameStatus.OPEN || requested == GameStatus.CANCELLED;
            case OPEN -> requested == GameStatus.IN_PROGRESS || requested == GameStatus.CANCELLED;
            case IN_PROGRESS -> requested == GameStatus.CONFERENCE;
            case CONFERENCE -> requested == GameStatus.FINISHED;
            case FINISHED, CANCELLED -> false;
        };
    }

    private void validateReferences(UUID roundId, UUID homeTeamId, UUID awayTeamId, UUID venueId) {
        roundLookup.assertExists(roundId);
        teamLookup.assertExists(homeTeamId);
        teamLookup.assertExists(awayTeamId);

        if (venueId != null) {
            venueLookup.assertExists(venueId);
        }

        if (homeTeamId.equals(awayTeamId)) {
            throw new SameTeamGameException();
        }
    }

    private GameEntity findEntityById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new GameNotFoundException(id));
    }

}
