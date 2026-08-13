package br.com.flagplatform.game.service;

import br.com.flagplatform.category.CategoryLookup;
import br.com.flagplatform.common.enums.GameStatus;
import br.com.flagplatform.competition.CompetitionLookup;
import br.com.flagplatform.competition.exception.CompetitionNotFoundException;
import br.com.flagplatform.game.GameResultRegisteredEvent;
import br.com.flagplatform.game.dto.request.CreateGameRequest;
import br.com.flagplatform.game.dto.request.RegisterGameResultRequest;
import br.com.flagplatform.game.dto.request.UpdateGameRequest;
import br.com.flagplatform.game.dto.response.GameResponse;
import br.com.flagplatform.game.dto.response.GameSummaryResponse;
import br.com.flagplatform.game.entity.GameEntity;
import br.com.flagplatform.game.exception.GameNotFoundException;
import br.com.flagplatform.game.exception.GameNotInProgressException;
import br.com.flagplatform.game.exception.InvalidGameStatusTransitionException;
import br.com.flagplatform.game.exception.SameTeamGameException;
import br.com.flagplatform.game.mapper.GameMapper;
import br.com.flagplatform.game.repository.GameRepository;
import br.com.flagplatform.round.RoundInfo;
import br.com.flagplatform.round.RoundLookup;
import br.com.flagplatform.round.exception.RoundNotFoundException;
import br.com.flagplatform.team.TeamInfo;
import br.com.flagplatform.team.TeamLookup;
import br.com.flagplatform.team.exception.TeamNotFoundException;
import br.com.flagplatform.venue.VenueLookup;
import br.com.flagplatform.venue.exception.VenueNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GameServiceTest {

    @Mock
    private GameMapper mapper;

    @Mock
    private GameRepository repository;

    @Mock
    private CompetitionLookup competitionLookup;

    @Mock
    private CategoryLookup categoryLookup;

    @Mock
    private RoundLookup roundLookup;

    @Mock
    private VenueLookup venueLookup;

    @Mock
    private TeamLookup teamLookup;

    @Mock
    private ApplicationEventPublisher applicationEventPublisher;

    @InjectMocks
    private GameService service;

    @Test
    void create_savesGameAfterValidatingReferences_withScheduledStatus() {
        UUID roundId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID venueId = UUID.randomUUID();
        CreateGameRequest request = createRequest(roundId, homeTeamId, awayTeamId, venueId);
        GameEntity entity = entity(roundId, homeTeamId, awayTeamId, venueId, request.scheduledAt(), null);
        GameResponse expected = response(entity);

        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        GameResponse result = service.create(request);

        assertThat(result).isSameAs(expected);
        assertThat(entity.getStatus()).isEqualTo(GameStatus.SCHEDULED);
        verify(roundLookup).assertExists(roundId);
        verify(teamLookup).assertExists(homeTeamId);
        verify(teamLookup).assertExists(awayTeamId);
        verify(venueLookup).assertExists(venueId);
        verify(repository).save(entity);
    }

    @Test
    void create_setsScheduledStatusWhenEntityHasNoStatus() {
        UUID roundId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        CreateGameRequest request = createRequest(roundId, homeTeamId, awayTeamId, null);
        GameEntity entity = entity(roundId, homeTeamId, awayTeamId, null, request.scheduledAt(), null);

        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(response(entity));

        service.create(request);

        assertThat(entity.getStatus()).isEqualTo(GameStatus.SCHEDULED);
    }

    @Test
    void create_throwsWhenRoundDoesNotExist() {
        UUID roundId = UUID.randomUUID();
        CreateGameRequest request = createRequest(roundId, UUID.randomUUID(), UUID.randomUUID(), null);

        doThrow(new RoundNotFoundException(roundId))
                .when(roundLookup).assertExists(roundId);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(RoundNotFoundException.class);

        verify(teamLookup, never()).assertExists(any());
        verify(repository, never()).save(any());
    }

    @Test
    void create_throwsWhenTeamDoesNotExist() {
        UUID homeTeamId = UUID.randomUUID();
        CreateGameRequest request = createRequest(UUID.randomUUID(), homeTeamId, UUID.randomUUID(), null);

        doThrow(new TeamNotFoundException(homeTeamId))
                .when(teamLookup).assertExists(homeTeamId);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(TeamNotFoundException.class);

        verify(venueLookup, never()).assertExists(any());
        verify(repository, never()).save(any());
    }

    @Test
    void create_throwsWhenVenueDoesNotExist() {
        UUID venueId = UUID.randomUUID();
        CreateGameRequest request = createRequest(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), venueId);

        doThrow(new VenueNotFoundException(venueId))
                .when(venueLookup).assertExists(venueId);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(VenueNotFoundException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void create_throwsWhenHomeAndAwayTeamsAreTheSame() {
        UUID sameTeamId = UUID.randomUUID();
        CreateGameRequest request = createRequest(
                UUID.randomUUID(), sameTeamId, sameTeamId, null);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(SameTeamGameException.class);

        verify(roundLookup).assertExists(request.roundId());
        verify(teamLookup, times(2)).assertExists(sameTeamId);
        verify(repository, never()).save(any());
    }

    @Test
    void findByRoundId_returnsGamesOrderedByScheduledAt() {
        UUID roundId = UUID.randomUUID();
        List<GameEntity> entities = List.of(
                entity(roundId, UUID.randomUUID(), UUID.randomUUID(), null,
                        LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.SCHEDULED),
                entity(roundId, UUID.randomUUID(), UUID.randomUUID(), null,
                        LocalDateTime.of(2026, 2, 1, 15, 0), GameStatus.SCHEDULED));
        List<GameResponse> expected = entities.stream()
                .map(this::response)
                .toList();

        when(repository.findAllByRoundIdOrderByScheduledAtAsc(roundId)).thenReturn(entities);
        when(mapper.toResponseList(entities)).thenReturn(expected);

        List<GameResponse> result = service.findByRoundId(roundId);

        assertThat(result).hasSize(2).isSameAs(expected);
    }

    @Test
    void findById_returnsGameWhenFound() {
        UUID id = UUID.randomUUID();
        GameEntity entity = entity(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.SCHEDULED);
        GameResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(mapper.toResponse(entity)).thenReturn(expected);

        GameResponse result = service.findById(id);

        assertThat(result).isSameAs(expected);
    }

    @Test
    void findById_throwsWhenGameNotFound() {
        UUID id = UUID.randomUUID();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.findById(id))
                .isInstanceOf(GameNotFoundException.class);
    }

    @Test
    void findByCompetitionId_throwsWhenCompetitionDoesNotExist() {
        UUID competitionId = UUID.randomUUID();

        doThrow(new CompetitionNotFoundException(competitionId))
                .when(competitionLookup).assertExists(competitionId);

        assertThatThrownBy(() -> service.findByCompetitionId(competitionId))
                .isInstanceOf(CompetitionNotFoundException.class);

        verify(categoryLookup, never()).findCategoryIdsByCompetitionId(any());
        verify(repository, never()).findAllByRoundIdInOrderByScheduledAtAsc(any());
    }

    @Test
    void findByCompetitionId_withoutCategories_returnsEmptyList() {
        UUID competitionId = UUID.randomUUID();

        when(categoryLookup.findCategoryIdsByCompetitionId(competitionId)).thenReturn(List.of());

        List<GameSummaryResponse> result = service.findByCompetitionId(competitionId);

        assertThat(result).isEmpty();
        verify(roundLookup, never()).findRoundInfoByCategoryIds(any());
        verify(repository, never()).findAllByRoundIdInOrderByScheduledAtAsc(any());
    }

    @Test
    void findByCompetitionId_withoutRounds_returnsEmptyList() {
        UUID competitionId = UUID.randomUUID();
        UUID categoryId = UUID.randomUUID();

        when(categoryLookup.findCategoryIdsByCompetitionId(competitionId))
                .thenReturn(List.of(categoryId));
        when(roundLookup.findRoundInfoByCategoryIds(List.of(categoryId))).thenReturn(List.of());

        List<GameSummaryResponse> result = service.findByCompetitionId(competitionId);

        assertThat(result).isEmpty();
        verify(repository, never()).findAllByRoundIdInOrderByScheduledAtAsc(any());
    }

    @Test
    void findByCompetitionId_returnsGamesOrderedByScheduledAt_withTeamAndVenueNames() {
        UUID competitionId = UUID.randomUUID();
        UUID categoryId = UUID.randomUUID();
        UUID roundId1 = UUID.randomUUID();
        UUID roundId2 = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID otherHomeTeamId = UUID.randomUUID();
        UUID otherAwayTeamId = UUID.randomUUID();
        UUID venueId = UUID.randomUUID();

        when(categoryLookup.findCategoryIdsByCompetitionId(competitionId))
                .thenReturn(List.of(categoryId));
        when(roundLookup.findRoundInfoByCategoryIds(List.of(categoryId)))
                .thenReturn(List.of(new RoundInfo(roundId1, 1), new RoundInfo(roundId2, 2)));
        when(teamLookup.findTeamInfoById(homeTeamId)).thenReturn(new TeamInfo(homeTeamId, "Tritões"));
        when(teamLookup.findTeamInfoById(awayTeamId)).thenReturn(new TeamInfo(awayTeamId, "Águias"));
        when(teamLookup.findTeamInfoById(otherHomeTeamId))
                .thenReturn(new TeamInfo(otherHomeTeamId, "Furacão"));
        when(teamLookup.findTeamInfoById(otherAwayTeamId))
                .thenReturn(new TeamInfo(otherAwayTeamId, "Trovões"));
        when(venueLookup.findNameById(venueId)).thenReturn("Arena Central");

        GameEntity later = entity(roundId2, homeTeamId, awayTeamId, venueId,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.SCHEDULED);
        GameEntity earlier = entity(roundId1, otherHomeTeamId, otherAwayTeamId, null,
                LocalDateTime.of(2026, 2, 1, 15, 0), GameStatus.SCHEDULED);

        when(repository.findAllByRoundIdInOrderByScheduledAtAsc(anyList()))
                .thenReturn(List.of(earlier, later));

        List<GameSummaryResponse> result = service.findByCompetitionId(competitionId);

        assertThat(result).hasSize(2);
        assertThat(result.getFirst().roundNumber()).isEqualTo(1);
        assertThat(result.getFirst().homeTeamName()).isEqualTo("Furacão");
        assertThat(result.getFirst().awayTeamName()).isEqualTo("Trovões");
        assertThat(result.getFirst().venueId()).isNull();
        assertThat(result.getFirst().venueName()).isNull();
        assertThat(result.getFirst().scheduledAt())
                .isEqualTo(LocalDateTime.of(2026, 2, 1, 15, 0));
        assertThat(result.getFirst().status()).isEqualTo(GameStatus.SCHEDULED);

        assertThat(result.getLast().roundNumber()).isEqualTo(2);
        assertThat(result.getLast().homeTeamName()).isEqualTo("Tritões");
        assertThat(result.getLast().awayTeamName()).isEqualTo("Águias");
        assertThat(result.getLast().venueId()).isEqualTo(venueId);
        assertThat(result.getLast().venueName()).isEqualTo("Arena Central");
        assertThat(result.getLast().scheduledAt())
                .isEqualTo(LocalDateTime.of(2026, 2, 1, 19, 0));
        assertThat(result.getLast().status()).isEqualTo(GameStatus.SCHEDULED);

        verify(competitionLookup).assertExists(competitionId);
        verify(repository).findAllByRoundIdInOrderByScheduledAtAsc(anyList());
    }

    @Test
    void update_updatesExistingGame() {
        UUID id = UUID.randomUUID();
        UUID roundId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID venueId = UUID.randomUUID();
        UpdateGameRequest request = updateRequest(roundId, homeTeamId, awayTeamId, venueId);
        GameEntity entity = entity(
                roundId, homeTeamId, awayTeamId, null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.SCHEDULED);
        GameResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        GameResponse result = service.update(id, request);

        assertThat(result).isSameAs(expected);
        verify(roundLookup).assertExists(roundId);
        verify(teamLookup).assertExists(homeTeamId);
        verify(teamLookup).assertExists(awayTeamId);
        verify(venueLookup).assertExists(venueId);
        verify(mapper).updateEntity(entity, request);
        verify(repository).save(entity);
    }

    @Test
    void update_throwsWhenGameNotFound() {
        UUID id = UUID.randomUUID();
        UpdateGameRequest request = updateRequest(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null);

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(GameNotFoundException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void update_throwsWhenHomeAndAwayTeamsAreTheSame() {
        UUID id = UUID.randomUUID();
        UUID sameTeamId = UUID.randomUUID();
        UpdateGameRequest request = updateRequest(
                UUID.randomUUID(), sameTeamId, sameTeamId, null);
        GameEntity entity = entity(
                UUID.randomUUID(), sameTeamId, UUID.randomUUID(), null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.SCHEDULED);

        when(repository.findById(id)).thenReturn(Optional.of(entity));

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(SameTeamGameException.class);

        verify(repository, never()).save(any());
        verify(mapper, never()).updateEntity(eq(entity), any(UpdateGameRequest.class));
    }

    @Test
    void updateStatus_scheduledToInProgress_updatesStatus() {
        UUID id = UUID.randomUUID();
        GameEntity entity = entity(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.SCHEDULED);
        GameResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        GameResponse result = service.updateStatus(id, GameStatus.IN_PROGRESS);

        assertThat(result).isSameAs(expected);
        assertThat(entity.getStatus()).isEqualTo(GameStatus.IN_PROGRESS);
        verify(repository).save(entity);
    }

    @Test
    void updateStatus_scheduledToCancelled_updatesStatus() {
        UUID id = UUID.randomUUID();
        GameEntity entity = entity(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.SCHEDULED);
        GameResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        GameResponse result = service.updateStatus(id, GameStatus.CANCELLED);

        assertThat(result).isSameAs(expected);
        assertThat(entity.getStatus()).isEqualTo(GameStatus.CANCELLED);
        verify(repository).save(entity);
    }

    @Test
    void updateStatus_inProgressToFinished_updatesStatus() {
        UUID id = UUID.randomUUID();
        GameEntity entity = entity(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.IN_PROGRESS);
        GameResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        GameResponse result = service.updateStatus(id, GameStatus.FINISHED);

        assertThat(result).isSameAs(expected);
        assertThat(entity.getStatus()).isEqualTo(GameStatus.FINISHED);
        verify(repository).save(entity);
    }

    @Test
    void updateStatus_inProgressToCancelled_throwsInvalidTransition() {
        UUID id = UUID.randomUUID();
        GameEntity entity = entity(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.IN_PROGRESS);

        when(repository.findById(id)).thenReturn(Optional.of(entity));

        assertThatThrownBy(() -> service.updateStatus(id, GameStatus.CANCELLED))
                .isInstanceOf(InvalidGameStatusTransitionException.class);

        assertThat(entity.getStatus()).isEqualTo(GameStatus.IN_PROGRESS);
        verify(repository, never()).save(any());
    }

    @Test
    void updateStatus_scheduledToScheduled_throwsInvalidTransition() {
        UUID id = UUID.randomUUID();
        GameEntity entity = entity(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.SCHEDULED);

        when(repository.findById(id)).thenReturn(Optional.of(entity));

        assertThatThrownBy(() -> service.updateStatus(id, GameStatus.SCHEDULED))
                .isInstanceOf(InvalidGameStatusTransitionException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void updateStatus_finishedToScheduled_throwsInvalidTransition() {
        UUID id = UUID.randomUUID();
        GameEntity entity = entity(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.FINISHED);

        when(repository.findById(id)).thenReturn(Optional.of(entity));

        assertThatThrownBy(() -> service.updateStatus(id, GameStatus.SCHEDULED))
                .isInstanceOf(InvalidGameStatusTransitionException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void updateStatus_gameNotFound_throws() {
        UUID id = UUID.randomUUID();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.updateStatus(id, GameStatus.IN_PROGRESS))
                .isInstanceOf(GameNotFoundException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void registerResult_inProgressGame_savesScoresAndPublishesEvent() {
        UUID id = UUID.randomUUID();
        UUID roundId = UUID.randomUUID();
        UUID categoryId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        RegisterGameResultRequest request = new RegisterGameResultRequest(3, 1);
        GameEntity entity = entity(roundId, homeTeamId, awayTeamId, null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.IN_PROGRESS);
        entity.setId(id);
        GameResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.save(entity)).thenReturn(entity);
        when(roundLookup.findCategoryId(roundId)).thenReturn(categoryId);
        when(mapper.toResponse(entity)).thenReturn(expected);

        GameResponse result = service.registerResult(id, request);

        assertThat(result).isSameAs(expected);
        assertThat(entity.getHomeScore()).isEqualTo(3);
        assertThat(entity.getAwayScore()).isEqualTo(1);
        assertThat(entity.getStatus()).isEqualTo(GameStatus.FINISHED);
        verify(repository).save(entity);

        ArgumentCaptor<GameResultRegisteredEvent> captor =
                ArgumentCaptor.forClass(GameResultRegisteredEvent.class);
        verify(applicationEventPublisher).publishEvent(captor.capture());
        GameResultRegisteredEvent event = captor.getValue();
        assertThat(event.gameId()).isEqualTo(id);
        assertThat(event.categoryId()).isEqualTo(categoryId);
    }

    @Test
    void registerResult_scheduledGame_throws() {
        UUID id = UUID.randomUUID();
        GameEntity entity = entity(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.SCHEDULED);

        when(repository.findById(id)).thenReturn(Optional.of(entity));

        assertThatThrownBy(() -> service.registerResult(id, new RegisterGameResultRequest(2, 0)))
                .isInstanceOf(GameNotInProgressException.class);

        assertThat(entity.getStatus()).isEqualTo(GameStatus.SCHEDULED);
        assertThat(entity.getHomeScore()).isNull();
        assertThat(entity.getAwayScore()).isNull();
        verify(repository, never()).save(any());
        verify(applicationEventPublisher, never()).publishEvent(any(Object.class));
    }

    @Test
    void registerResult_finishedGame_throws() {
        UUID id = UUID.randomUUID();
        GameEntity entity = entity(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.FINISHED);

        when(repository.findById(id)).thenReturn(Optional.of(entity));

        assertThatThrownBy(() -> service.registerResult(id, new RegisterGameResultRequest(2, 0)))
                .isInstanceOf(GameNotInProgressException.class);

        assertThat(entity.getStatus()).isEqualTo(GameStatus.FINISHED);
        verify(repository, never()).save(any());
        verify(applicationEventPublisher, never()).publishEvent(any(Object.class));
    }

    @Test
    void registerResult_cancelledGame_throws() {
        UUID id = UUID.randomUUID();
        GameEntity entity = entity(
                UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.CANCELLED);

        when(repository.findById(id)).thenReturn(Optional.of(entity));

        assertThatThrownBy(() -> service.registerResult(id, new RegisterGameResultRequest(2, 0)))
                .isInstanceOf(GameNotInProgressException.class);

        assertThat(entity.getStatus()).isEqualTo(GameStatus.CANCELLED);
        verify(repository, never()).save(any());
        verify(applicationEventPublisher, never()).publishEvent(any(Object.class));
    }

    @Test
    void registerResult_gameNotFound_throws() {
        UUID id = UUID.randomUUID();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.registerResult(id, new RegisterGameResultRequest(2, 0)))
                .isInstanceOf(GameNotFoundException.class);

        verify(repository, never()).save(any());
        verify(applicationEventPublisher, never()).publishEvent(any(Object.class));
    }

    @Test
    void findFinishedByCategoryId_mapsFinishedGames() {
        UUID categoryId = UUID.randomUUID();
        UUID roundId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        GameEntity finished = entity(roundId, homeTeamId, awayTeamId, null,
                LocalDateTime.of(2026, 2, 1, 19, 0), GameStatus.FINISHED);
        finished.setHomeScore(3);
        finished.setAwayScore(1);

        when(roundLookup.findRoundIdsByCategoryId(categoryId)).thenReturn(List.of(roundId));
        when(repository.findAllByRoundIdInAndStatus(List.of(roundId), GameStatus.FINISHED))
                .thenReturn(List.of(finished));

        var result = service.findFinishedByCategoryId(categoryId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().homeTeamId()).isEqualTo(homeTeamId);
        assertThat(result.getFirst().awayTeamId()).isEqualTo(awayTeamId);
        assertThat(result.getFirst().homeScore()).isEqualTo(3);
        assertThat(result.getFirst().awayScore()).isEqualTo(1);
        // Só jogos FINISHED são consultados: jogos IN_PROGRESS/SCHEDULED não
        // chegam ao módulo standing (filtro de status no lookup).
        verify(repository).findAllByRoundIdInAndStatus(List.of(roundId), GameStatus.FINISHED);
    }

    @Test
    void findFinishedByCategoryId_withoutRounds_returnsEmptyList() {
        UUID categoryId = UUID.randomUUID();

        when(roundLookup.findRoundIdsByCategoryId(categoryId)).thenReturn(List.of());

        var result = service.findFinishedByCategoryId(categoryId);

        assertThat(result).isEmpty();
        verify(repository, never()).findAllByRoundIdInAndStatus(any(), any());
    }

    private CreateGameRequest createRequest(UUID roundId, UUID homeTeamId, UUID awayTeamId,
                                            UUID venueId) {
        return new CreateGameRequest(
                roundId, homeTeamId, awayTeamId, venueId,
                LocalDateTime.of(2026, 2, 1, 19, 0));
    }

    private UpdateGameRequest updateRequest(UUID roundId, UUID homeTeamId, UUID awayTeamId,
                                            UUID venueId) {
        return new UpdateGameRequest(
                roundId, homeTeamId, awayTeamId, venueId,
                LocalDateTime.of(2026, 2, 1, 21, 0));
    }

    private GameEntity entity(UUID roundId, UUID homeTeamId, UUID awayTeamId, UUID venueId,
                              LocalDateTime scheduledAt, GameStatus status) {
        GameEntity entity = new GameEntity();
        entity.setId(UUID.randomUUID());
        entity.setRoundId(roundId);
        entity.setHomeTeamId(homeTeamId);
        entity.setAwayTeamId(awayTeamId);
        entity.setVenueId(venueId);
        entity.setScheduledAt(scheduledAt);
        entity.setStatus(status);
        return entity;
    }

    private GameResponse response(GameEntity entity) {
        return new GameResponse(
                entity.getId(),
                entity.getRoundId(),
                entity.getHomeTeamId(),
                entity.getAwayTeamId(),
                entity.getVenueId(),
                entity.getScheduledAt(),
                entity.getStatus(),
                entity.getHomeScore(),
                entity.getAwayScore(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

}
