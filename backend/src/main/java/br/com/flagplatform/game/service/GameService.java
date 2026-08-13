package br.com.flagplatform.game.service;

import br.com.flagplatform.common.enums.GameStatus;
import br.com.flagplatform.game.dto.request.CreateGameRequest;
import br.com.flagplatform.game.dto.request.UpdateGameRequest;
import br.com.flagplatform.game.dto.response.GameResponse;
import br.com.flagplatform.game.entity.GameEntity;
import br.com.flagplatform.game.exception.GameNotFoundException;
import br.com.flagplatform.game.exception.InvalidGameStatusTransitionException;
import br.com.flagplatform.game.exception.SameTeamGameException;
import br.com.flagplatform.game.mapper.GameMapper;
import br.com.flagplatform.game.repository.GameRepository;
import br.com.flagplatform.round.RoundLookup;
import br.com.flagplatform.team.TeamLookup;
import br.com.flagplatform.venue.VenueLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class GameService {

    private final GameMapper mapper;
    private final GameRepository repository;
    private final RoundLookup roundLookup;
    private final VenueLookup venueLookup;
    private final TeamLookup teamLookup;

    @Transactional
    public GameResponse create(CreateGameRequest request) {
        validateReferences(request.roundId(), request.homeTeamId(), request.awayTeamId(), request.venueId());

        GameEntity entity = mapper.toEntity(request);
        if (entity.getStatus() == null) {
            entity.setStatus(GameStatus.SCHEDULED);
        }

        return mapper.toResponse(repository.save(entity));
    }

    public List<GameResponse> findByRoundId(UUID roundId) {
        return mapper.toResponseList(repository.findAllByRoundIdOrderByScheduledAtAsc(roundId));
    }

    public GameResponse findById(UUID id) {
        return mapper.toResponse(findEntityById(id));
    }

    @Transactional
    public GameResponse update(UUID id, UpdateGameRequest request) {
        GameEntity entity = findEntityById(id);
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

    private boolean isValidTransition(GameStatus current, GameStatus requested) {
        return switch (current) {
            case SCHEDULED ->
                    requested == GameStatus.IN_PROGRESS || requested == GameStatus.CANCELLED;
            case IN_PROGRESS -> requested == GameStatus.FINISHED;
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
