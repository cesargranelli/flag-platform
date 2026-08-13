package br.com.flagplatform.game.service;

import br.com.flagplatform.common.enums.GameStatus;
import br.com.flagplatform.game.dto.request.CreateGameRequest;
import br.com.flagplatform.game.dto.request.UpdateGameRequest;
import br.com.flagplatform.game.dto.response.GameResponse;
import br.com.flagplatform.game.entity.GameEntity;
import br.com.flagplatform.game.exception.GameNotFoundException;
import br.com.flagplatform.game.exception.SameTeamGameException;
import br.com.flagplatform.game.mapper.GameMapper;
import br.com.flagplatform.game.repository.GameRepository;
import br.com.flagplatform.round.RoundLookup;
import br.com.flagplatform.round.exception.RoundNotFoundException;
import br.com.flagplatform.team.TeamLookup;
import br.com.flagplatform.team.exception.TeamNotFoundException;
import br.com.flagplatform.venue.VenueLookup;
import br.com.flagplatform.venue.exception.VenueNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
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
    private RoundLookup roundLookup;

    @Mock
    private VenueLookup venueLookup;

    @Mock
    private TeamLookup teamLookup;

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
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

}
