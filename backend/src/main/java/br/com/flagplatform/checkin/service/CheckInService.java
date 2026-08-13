package br.com.flagplatform.checkin.service;

import br.com.flagplatform.athlete.AthleteInfo;
import br.com.flagplatform.athlete.AthleteLookup;
import br.com.flagplatform.checkin.dto.request.CheckInStatusRequest;
import br.com.flagplatform.checkin.dto.response.CheckInResponse;
import br.com.flagplatform.checkin.entity.CheckInEntity;
import br.com.flagplatform.checkin.exception.AthleteNotInGameException;
import br.com.flagplatform.checkin.repository.CheckInRepository;
import br.com.flagplatform.common.enums.CheckInStatus;
import br.com.flagplatform.game.GameInfo;
import br.com.flagplatform.game.GameLookup;
import br.com.flagplatform.roster.RosterLookup;
import br.com.flagplatform.team.TeamLookup;
import br.com.flagplatform.user.UserLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class CheckInService {

    private final CheckInRepository repository;
    private final GameLookup gameLookup;
    private final RosterLookup rosterLookup;
    private final AthleteLookup athleteLookup;
    private final TeamLookup teamLookup;
    private final UserLookup userLookup;

    public List<CheckInResponse> getCheckinList(UUID gameId) {
        GameInfo game = gameLookup.findGameInfoById(gameId);

        Map<UUID, CheckInEntity> existing = repository.findAllByGameId(gameId).stream()
                .collect(Collectors.toMap(CheckInEntity::getAthleteId, entry -> entry));

        List<CheckInResponse> result = new ArrayList<>();
        result.addAll(buildTeamRoster(game, game.homeTeamId(), existing));
        result.addAll(buildTeamRoster(game, game.awayTeamId(), existing));

        return result;
    }

    @Transactional
    public CheckInResponse checkin(UUID gameId, UUID athleteId,
                                   CheckInStatusRequest request, String validatedByEmail) {
        GameInfo game = gameLookup.findGameInfoById(gameId);
        UUID teamId = resolveTeam(game, athleteId);
        UUID validatedBy = userLookup.findUserIdByEmail(validatedByEmail);

        CheckInEntity entity = repository.findByGameIdAndAthleteId(gameId, athleteId)
                .orElseGet(() -> {
                    CheckInEntity created = new CheckInEntity();
                    created.setGameId(gameId);
                    created.setTeamId(teamId);
                    created.setAthleteId(athleteId);
                    return created;
                });

        entity.setStatus(request.status());
        entity.setValidatedBy(validatedBy);
        entity.setValidatedAt(LocalDateTime.now());

        CheckInEntity saved = repository.save(entity);

        return buildResponse(gameId, saved.getTeamId(), athleteId, saved);
    }

    private List<CheckInResponse> buildTeamRoster(GameInfo game, UUID teamId,
                                                  Map<UUID, CheckInEntity> existing) {
        String teamName = teamLookup.findTeamInfoById(teamId).name();

        return rosterLookup.findAthleteIdsByTeamId(teamId).stream()
                .map(athleteId -> buildResponse(game.id(), teamId, athleteId, existing.get(athleteId)))
                .sorted(Comparator.comparing(CheckInResponse::number,
                        Comparator.nullsLast(Integer::compareTo)))
                .toList();
    }

    private UUID resolveTeam(GameInfo game, UUID athleteId) {
        if (rosterLookup.findAthleteIdsByTeamId(game.homeTeamId()).contains(athleteId)) {
            return game.homeTeamId();
        }
        if (rosterLookup.findAthleteIdsByTeamId(game.awayTeamId()).contains(athleteId)) {
            return game.awayTeamId();
        }
        throw new AthleteNotInGameException(game.id(), athleteId);
    }

    private CheckInResponse buildResponse(UUID gameId, UUID teamId, UUID athleteId,
                                          CheckInEntity checkIn) {
        String teamName = teamLookup.findTeamInfoById(teamId).name();
        AthleteInfo athlete = athleteLookup.findAthleteInfoById(athleteId);

        return new CheckInResponse(
                gameId,
                teamId,
                teamName,
                athleteId,
                athlete.name(),
                athlete.nickname(),
                athlete.number(),
                athlete.position(),
                checkIn != null ? checkIn.getStatus() : null,
                checkIn != null ? checkIn.getValidatedBy() : null,
                checkIn != null ? checkIn.getValidatedAt() : null);
    }

}
