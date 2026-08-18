package br.com.flagplatform.checkin.service;

import br.com.flagplatform.athlete.AthleteInfo;
import br.com.flagplatform.athlete.AthleteLookup;
import br.com.flagplatform.checkin.dto.request.CheckInStatusRequest;
import br.com.flagplatform.checkin.dto.request.MatchNumberRequest;
import br.com.flagplatform.checkin.dto.response.CheckInResponse;
import br.com.flagplatform.checkin.dto.response.ValidationResponse;
import br.com.flagplatform.checkin.entity.CheckInEntity;
import br.com.flagplatform.checkin.exception.AthleteNotInGameException;
import br.com.flagplatform.checkin.exception.DuplicateMatchNumberException;
import br.com.flagplatform.checkin.exception.GameNotInProgressException;
import br.com.flagplatform.checkin.repository.CheckInRepository;
import br.com.flagplatform.common.enums.AthletePosition;
import br.com.flagplatform.common.enums.CheckInStatus;
import br.com.flagplatform.common.enums.GameStatus;
import br.com.flagplatform.game.GameInfo;
import br.com.flagplatform.game.GameLookup;
import br.com.flagplatform.roster.RosterLookup;
import br.com.flagplatform.team.TeamInfo;
import br.com.flagplatform.team.TeamLookup;
import br.com.flagplatform.user.UserLookup;
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
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CheckInServiceTest {

    @Mock
    private CheckInRepository repository;

    @Mock
    private GameLookup gameLookup;

    @Mock
    private RosterLookup rosterLookup;

    @Mock
    private AthleteLookup athleteLookup;

    @Mock
    private TeamLookup teamLookup;

    @Mock
    private UserLookup userLookup;

    @InjectMocks
    private CheckInService service;

    @Test
    void getCheckinList_returnsBothTeamsOrderedByJerseyNumber() {
        UUID gameId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID homeAthlete = UUID.randomUUID();
        UUID awayAthlete = UUID.randomUUID();

        when(gameLookup.findGameInfoById(gameId))
                .thenReturn(new GameInfo(gameId, homeTeamId, awayTeamId, GameStatus.SCHEDULED));
        when(repository.findAllByGameId(gameId)).thenReturn(List.of());
        when(teamLookup.findTeamInfoById(homeTeamId))
                .thenReturn(new TeamInfo(homeTeamId, "Tritões"));
        when(teamLookup.findTeamInfoById(awayTeamId))
                .thenReturn(new TeamInfo(awayTeamId, "Águias"));
        when(rosterLookup.findAthleteIdsByTeamId(homeTeamId)).thenReturn(List.of(homeAthlete));
        when(rosterLookup.findAthleteIdsByTeamId(awayTeamId)).thenReturn(List.of(awayAthlete));
        when(athleteLookup.findAthleteInfoById(homeAthlete))
                .thenReturn(new AthleteInfo(homeAthlete, "João Silva", "João", AthletePosition.QB, 7, null));
        when(athleteLookup.findAthleteInfoById(awayAthlete))
                .thenReturn(new AthleteInfo(awayAthlete, "Bia Santos", "Bia", AthletePosition.DB, 21, null));

        List<CheckInResponse> response = service.getCheckinList(gameId);

        assertThat(response).hasSize(2);
        assertThat(response.get(0).teamName()).isEqualTo("Tritões");
        assertThat(response.get(0).athleteName()).isEqualTo("João Silva");
        assertThat(response.get(0).status()).isNull();
        assertThat(response.get(1).teamName()).isEqualTo("Águias");
    }

    @Test
    void getCheckinList_returnsExistingCheckInStatus() {
        UUID gameId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();

        CheckInEntity checkIn = checkIn(gameId, homeTeamId, athleteId, CheckInStatus.PRESENT);

        when(gameLookup.findGameInfoById(gameId))
                .thenReturn(new GameInfo(gameId, homeTeamId, awayTeamId, GameStatus.SCHEDULED));
        when(repository.findAllByGameId(gameId)).thenReturn(List.of(checkIn));
        when(teamLookup.findTeamInfoById(homeTeamId))
                .thenReturn(new TeamInfo(homeTeamId, "Tritões"));
        when(teamLookup.findTeamInfoById(awayTeamId))
                .thenReturn(new TeamInfo(awayTeamId, "Águias"));
        when(rosterLookup.findAthleteIdsByTeamId(homeTeamId)).thenReturn(List.of(athleteId));
        when(rosterLookup.findAthleteIdsByTeamId(awayTeamId)).thenReturn(List.of());
        when(athleteLookup.findAthleteInfoById(athleteId))
                .thenReturn(new AthleteInfo(athleteId, "João Silva", "João", AthletePosition.QB, 7, null));

        List<CheckInResponse> response = service.getCheckinList(gameId);

        assertThat(response).hasSize(1);
        assertThat(response.get(0).status()).isEqualTo(CheckInStatus.PRESENT);
        assertThat(response.get(0).validatedBy()).isEqualTo(checkIn.getValidatedBy());
        assertThat(response.get(0).validatedAt()).isEqualTo(checkIn.getValidatedAt());
    }

    @Test
    void getCheckinList_throwsWhenGameNotFound() {
        UUID gameId = UUID.randomUUID();

        doThrow(new RuntimeException("game not found"))
                .when(gameLookup).findGameInfoById(gameId);

        assertThatThrownBy(() -> service.getCheckinList(gameId))
                .isInstanceOf(RuntimeException.class);

        verify(repository, never()).findAllByGameId(gameId);
    }

    @Test
    void checkin_marksPresent_andRegistersValidatedByAndAt() {
        UUID gameId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        CheckInStatusRequest request = new CheckInStatusRequest(CheckInStatus.PRESENT);

        when(gameLookup.findGameInfoById(gameId))
                .thenReturn(new GameInfo(gameId, homeTeamId, awayTeamId, GameStatus.SCHEDULED));
        when(rosterLookup.findAthleteIdsByTeamId(homeTeamId)).thenReturn(List.of(athleteId));
        when(userLookup.findUserIdByEmail("mesa@exemplo.com")).thenReturn(userId);
        when(repository.findByGameIdAndAthleteId(gameId, athleteId)).thenReturn(Optional.empty());
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(teamLookup.findTeamInfoById(homeTeamId))
                .thenReturn(new TeamInfo(homeTeamId, "Tritões"));
        when(athleteLookup.findAthleteInfoById(athleteId))
                .thenReturn(new AthleteInfo(athleteId, "João Silva", "João", AthletePosition.QB, 7, null));

        CheckInResponse response = service.checkin(gameId, athleteId, request, "mesa@exemplo.com");

        assertThat(response.status()).isEqualTo(CheckInStatus.PRESENT);
        assertThat(response.validatedBy()).isEqualTo(userId);
        assertThat(response.validatedAt()).isNotNull();
        verify(repository).save(any());
    }

    @Test
    void checkin_updatesExistingEntry() {
        UUID gameId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        CheckInStatusRequest request = new CheckInStatusRequest(CheckInStatus.NO_SHOW);
        CheckInEntity existing = checkIn(gameId, homeTeamId, athleteId, CheckInStatus.PRESENT);
        CheckInEntity saved = checkIn(gameId, homeTeamId, athleteId, CheckInStatus.NO_SHOW);

        when(gameLookup.findGameInfoById(gameId))
                .thenReturn(new GameInfo(gameId, homeTeamId, awayTeamId, GameStatus.SCHEDULED));
        when(rosterLookup.findAthleteIdsByTeamId(homeTeamId)).thenReturn(List.of(athleteId));
        when(userLookup.findUserIdByEmail("mesa@exemplo.com")).thenReturn(userId);
        when(repository.findByGameIdAndAthleteId(gameId, athleteId)).thenReturn(Optional.of(existing));
        when(repository.save(existing)).thenReturn(saved);
        when(teamLookup.findTeamInfoById(homeTeamId))
                .thenReturn(new TeamInfo(homeTeamId, "Tritões"));
        when(athleteLookup.findAthleteInfoById(athleteId))
                .thenReturn(new AthleteInfo(athleteId, "João Silva", "João", AthletePosition.QB, 7, null));

        CheckInResponse response = service.checkin(gameId, athleteId, request, "mesa@exemplo.com");

        assertThat(response.status()).isEqualTo(CheckInStatus.NO_SHOW);
        verify(repository).save(existing);
    }

    @Test
    void checkin_throwsWhenAthleteNotInRosters() {
        UUID gameId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();

        CheckInStatusRequest request = new CheckInStatusRequest(CheckInStatus.PRESENT);

        when(gameLookup.findGameInfoById(gameId))
                .thenReturn(new GameInfo(gameId, homeTeamId, awayTeamId, GameStatus.SCHEDULED));
        when(rosterLookup.findAthleteIdsByTeamId(homeTeamId)).thenReturn(List.of());
        when(rosterLookup.findAthleteIdsByTeamId(awayTeamId)).thenReturn(List.of());

        assertThatThrownBy(() -> service.checkin(gameId, athleteId, request, "mesa@exemplo.com"))
                .isInstanceOf(AthleteNotInGameException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void validate_marksPresent_duringInProgress() {
        UUID gameId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        when(gameLookup.findGameInfoById(gameId))
                .thenReturn(new GameInfo(gameId, homeTeamId, awayTeamId, GameStatus.IN_PROGRESS));
        when(athleteLookup.findAthleteInfoById(athleteId))
                .thenReturn(new AthleteInfo(athleteId, "João Silva", "João", AthletePosition.QB, 7, null));
        when(rosterLookup.findAthleteIdsByTeamId(homeTeamId)).thenReturn(List.of(athleteId));
        when(userLookup.findUserIdByEmail("mesa@exemplo.com")).thenReturn(userId);
        when(repository.findByGameIdAndAthleteId(gameId, athleteId)).thenReturn(Optional.empty());
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        ValidationResponse response = service.validate(gameId, athleteId, "mesa@exemplo.com");

        assertThat(response.status()).isEqualTo(CheckInStatus.PRESENT);
        assertThat(response.teamId()).isEqualTo(homeTeamId);
        assertThat(response.validatedBy()).isEqualTo(userId);
        assertThat(response.validatedAt()).isNotNull();
        verify(repository).save(any());
    }

    @Test
    void validate_returnsNotRegistered_whenAthleteNotInRosters() {
        UUID gameId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();

        when(gameLookup.findGameInfoById(gameId))
                .thenReturn(new GameInfo(gameId, homeTeamId, awayTeamId, GameStatus.IN_PROGRESS));
        when(athleteLookup.findAthleteInfoById(athleteId))
                .thenReturn(new AthleteInfo(athleteId, "Zeca Silva", null, null, null, null));
        when(rosterLookup.findAthleteIdsByTeamId(homeTeamId)).thenReturn(List.of());
        when(rosterLookup.findAthleteIdsByTeamId(awayTeamId)).thenReturn(List.of());

        ValidationResponse response = service.validate(gameId, athleteId, "mesa@exemplo.com");

        assertThat(response.status()).isEqualTo(CheckInStatus.NOT_REGISTERED);
        assertThat(response.teamId()).isNull();
        assertThat(response.validatedBy()).isNull();
        verify(repository, never()).save(any());
    }

    @Test
    void validate_throwsWhenGameNotInProgress() {
        UUID gameId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();

        when(gameLookup.findGameInfoById(gameId))
                .thenReturn(new GameInfo(gameId, homeTeamId, awayTeamId, GameStatus.SCHEDULED));

        assertThatThrownBy(() -> service.validate(gameId, athleteId, "mesa@exemplo.com"))
                .isInstanceOf(GameNotInProgressException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void setMatchNumber_definesOverride() {
        UUID gameId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();

        CheckInEntity existing = checkIn(gameId, homeTeamId, athleteId, CheckInStatus.PRESENT);

        when(gameLookup.findGameInfoById(gameId))
                .thenReturn(new GameInfo(gameId, homeTeamId, awayTeamId, GameStatus.SCHEDULED));
        when(rosterLookup.findAthleteIdsByTeamId(homeTeamId)).thenReturn(List.of(athleteId));
        when(repository.findByGameIdAndAthleteId(gameId, athleteId)).thenReturn(Optional.of(existing));
        when(repository.existsByGameIdAndTeamIdAndMatchNumberAndAthleteIdNot(
                gameId, homeTeamId, 10, athleteId)).thenReturn(false);
        when(repository.save(existing)).thenReturn(existing);
        when(teamLookup.findTeamInfoById(homeTeamId))
                .thenReturn(new TeamInfo(homeTeamId, "Tritões"));
        when(athleteLookup.findAthleteInfoById(athleteId))
                .thenReturn(new AthleteInfo(athleteId, "João Silva", "João", AthletePosition.QB, 7, null));

        CheckInResponse response = service.setMatchNumber(gameId, athleteId, new MatchNumberRequest(10));

        assertThat(response.matchNumber()).isEqualTo(10);
        assertThat(response.athleteNumber()).isEqualTo(7);
        assertThat(response.number()).isEqualTo(10);
        assertThat(existing.getMatchNumber()).isEqualTo(10);
        verify(repository).save(existing);
    }

    @Test
    void setMatchNumber_clearOverride_returnsOfficial() {
        UUID gameId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();

        CheckInEntity existing = checkIn(gameId, homeTeamId, athleteId, CheckInStatus.PRESENT);
        existing.setMatchNumber(10);

        when(gameLookup.findGameInfoById(gameId))
                .thenReturn(new GameInfo(gameId, homeTeamId, awayTeamId, GameStatus.SCHEDULED));
        when(rosterLookup.findAthleteIdsByTeamId(homeTeamId)).thenReturn(List.of(athleteId));
        when(repository.findByGameIdAndAthleteId(gameId, athleteId)).thenReturn(Optional.of(existing));
        when(repository.save(existing)).thenReturn(existing);
        when(teamLookup.findTeamInfoById(homeTeamId))
                .thenReturn(new TeamInfo(homeTeamId, "Tritões"));
        when(athleteLookup.findAthleteInfoById(athleteId))
                .thenReturn(new AthleteInfo(athleteId, "João Silva", "João", AthletePosition.QB, 7, null));

        CheckInResponse response = service.setMatchNumber(gameId, athleteId, new MatchNumberRequest(null));

        assertThat(response.matchNumber()).isNull();
        assertThat(response.number()).isEqualTo(7);
        assertThat(existing.getMatchNumber()).isNull();
    }

    @Test
    void setMatchNumber_duplicateInSameTeam_throwsConflict() {
        UUID gameId = UUID.randomUUID();
        UUID homeTeamId = UUID.randomUUID();
        UUID awayTeamId = UUID.randomUUID();
        UUID athleteId = UUID.randomUUID();

        when(gameLookup.findGameInfoById(gameId))
                .thenReturn(new GameInfo(gameId, homeTeamId, awayTeamId, GameStatus.SCHEDULED));
        when(rosterLookup.findAthleteIdsByTeamId(homeTeamId)).thenReturn(List.of(athleteId));
        when(repository.existsByGameIdAndTeamIdAndMatchNumberAndAthleteIdNot(
                gameId, homeTeamId, 10, athleteId)).thenReturn(true);

        assertThatThrownBy(() -> service.setMatchNumber(
                gameId, athleteId, new MatchNumberRequest(10)))
                .isInstanceOf(DuplicateMatchNumberException.class);

        verify(repository, never()).save(any());
    }

    private CheckInEntity checkIn(UUID gameId, UUID teamId, UUID athleteId, CheckInStatus status) {
        CheckInEntity entity = new CheckInEntity();
        entity.setId(UUID.randomUUID());
        entity.setGameId(gameId);
        entity.setTeamId(teamId);
        entity.setAthleteId(athleteId);
        entity.setStatus(status);
        entity.setValidatedBy(UUID.randomUUID());
        entity.setValidatedAt(LocalDateTime.now());
        return entity;
    }

}
