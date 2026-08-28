package br.com.flagplatform.play.service;

import br.com.flagplatform.game.GameLookup;
import br.com.flagplatform.game.GameInfo;
import br.com.flagplatform.play.PlayLookup;
import br.com.flagplatform.play.dto.request.CreatePlayRequest;
import br.com.flagplatform.play.dto.response.PlayResponse;
import br.com.flagplatform.play.entity.PlayEntity;
import br.com.flagplatform.play.exception.PlayTeamNotInGameException;
import br.com.flagplatform.play.mapper.PlayMapper;
import br.com.flagplatform.play.repository.PlayRepository;
import br.com.flagplatform.team.TeamInfo;
import br.com.flagplatform.team.TeamLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class PlayService implements PlayLookup {

    private final PlayMapper mapper;
    private final PlayRepository repository;
    private final GameLookup gameLookup;
    private final TeamLookup teamLookup;

    public List<PlayResponse> findByGameId(UUID gameId) {
        return repository.findByGameIdOrderByCreatedAtDesc(gameId).stream()
                .map(play -> {
                    PlayResponse response = mapper.toResponse(play);
                    TeamInfo teamInfo = teamLookup.findTeamInfoById(play.getTeamId());
                    return new PlayResponse(
                            response.id(),
                            response.gameId(),
                            response.teamId(),
                            teamInfo != null ? teamInfo.name() : null,
                            response.playerName(),
                            response.receiverName(),
                            response.playType(),
                            response.description(),
                            response.yards(),
                            response.quarter(),
                            response.time(),
                            response.isFirstDown(),
                            response.isTouchdown(),
                            response.isTurnover()
                    );
                })
                .toList();
    }

    @Transactional
    public PlayResponse create(UUID gameId, CreatePlayRequest request) {
        GameInfo gameInfo = gameLookup.findGameInfoById(gameId);

        if (!gameInfo.homeTeamId().equals(request.teamId())
                && !gameInfo.awayTeamId().equals(request.teamId())) {
            throw new PlayTeamNotInGameException(gameId, request.teamId());
        }

        PlayEntity entity = mapper.toEntity(request);
        entity.setGameId(gameId);

        PlayEntity saved = repository.save(entity);

        TeamInfo teamInfo = teamLookup.findTeamInfoById(saved.getTeamId());
        PlayResponse response = mapper.toResponse(saved);
        return new PlayResponse(
                response.id(),
                response.gameId(),
                response.teamId(),
                teamInfo != null ? teamInfo.name() : null,
                response.playerName(),
                response.receiverName(),
                response.playType(),
                response.description(),
                response.yards(),
                response.quarter(),
                response.time(),
                response.isFirstDown(),
                response.isTouchdown(),
                response.isTurnover()
        );
    }

    @Override
    public boolean existsByGameId(UUID gameId) {
        return repository.existsByGameId(gameId);
    }

}
