package br.com.flagplatform.standing.service;

import br.com.flagplatform.game.FinishedGame;
import br.com.flagplatform.game.GameLookup;
import br.com.flagplatform.standing.dto.response.StandingResponse;
import br.com.flagplatform.standing.entity.StandingEntity;
import br.com.flagplatform.standing.repository.StandingRepository;
import br.com.flagplatform.team.TeamInfo;
import br.com.flagplatform.team.TeamLookup;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StandingServiceTest {

    @Mock
    private StandingRepository repository;

    @Mock
    private TeamLookup teamLookup;

    @Mock
    private GameLookup gameLookup;

    @InjectMocks
    private StandingService service;

    @Test
    void recalculate_computesStatsForAllTeams_includingDraw() {
        UUID categoryId = UUID.randomUUID();
        UUID team1 = UUID.randomUUID();
        UUID team2 = UUID.randomUUID();
        UUID team3 = UUID.randomUUID();
        UUID team4 = UUID.randomUUID();

        // Apenas jogos FINISHED chegam ao serviço: o GameLookup filtra por
        // GameStatus.FINISHED, então jogos IN_PROGRESS/SCHEDULED nunca entram
        // na lista abaixo (comportamento coberto no GameServiceTest e no
        // teste de integração end-to-end).
        when(teamLookup.findTeamIdsByCategoryId(categoryId))
                .thenReturn(List.of(team1, team2, team3, team4));
        when(gameLookup.findFinishedByCategoryId(categoryId)).thenReturn(List.of(
                new FinishedGame(team1, team2, 2, 1),
                new FinishedGame(team2, team3, 1, 1),
                new FinishedGame(team3, team4, 3, 0),
                new FinishedGame(team4, team1, 0, 2)));

        service.recalculate(categoryId);

        ArgumentCaptor<List<StandingEntity>> captor = ArgumentCaptor.forClass(List.class);
        verify(repository).saveAll(captor.capture());
        List<StandingEntity> saved = captor.getValue();
        assertThat(saved).hasSize(4);

        StandingEntity row1 = findByTeam(saved, team1);
        assertThat(row1.getCategoryId()).isEqualTo(categoryId);
        assertThat(row1.getPlayed()).isEqualTo(2);
        assertThat(row1.getWins()).isEqualTo(2);
        assertThat(row1.getDraws()).isZero();
        assertThat(row1.getLosses()).isZero();
        assertThat(row1.getGoalsFor()).isEqualTo(4);
        assertThat(row1.getGoalsAgainst()).isEqualTo(1);
        assertThat(row1.getPoints()).isEqualTo(6);

        StandingEntity row2 = findByTeam(saved, team2);
        assertThat(row2.getPlayed()).isEqualTo(2);
        assertThat(row2.getWins()).isZero();
        assertThat(row2.getDraws()).isEqualTo(1);
        assertThat(row2.getLosses()).isEqualTo(1);
        assertThat(row2.getGoalsFor()).isEqualTo(2);
        assertThat(row2.getGoalsAgainst()).isEqualTo(3);
        assertThat(row2.getPoints()).isEqualTo(1);

        StandingEntity row3 = findByTeam(saved, team3);
        assertThat(row3.getPlayed()).isEqualTo(2);
        assertThat(row3.getWins()).isEqualTo(1);
        assertThat(row3.getDraws()).isEqualTo(1);
        assertThat(row3.getLosses()).isZero();
        assertThat(row3.getGoalsFor()).isEqualTo(4);
        assertThat(row3.getGoalsAgainst()).isEqualTo(1);
        assertThat(row3.getPoints()).isEqualTo(4);

        StandingEntity row4 = findByTeam(saved, team4);
        assertThat(row4.getPlayed()).isEqualTo(2);
        assertThat(row4.getWins()).isZero();
        assertThat(row4.getDraws()).isZero();
        assertThat(row4.getLosses()).isEqualTo(2);
        assertThat(row4.getGoalsFor()).isZero();
        assertThat(row4.getGoalsAgainst()).isEqualTo(5);
        assertThat(row4.getPoints()).isZero();
    }

    @Test
    void recalculate_deletesBeforeSaving() {
        UUID categoryId = UUID.randomUUID();
        UUID team1 = UUID.randomUUID();

        when(teamLookup.findTeamIdsByCategoryId(categoryId)).thenReturn(List.of(team1));
        when(gameLookup.findFinishedByCategoryId(categoryId)).thenReturn(List.of());

        service.recalculate(categoryId);

        InOrder inOrder = inOrder(repository);
        inOrder.verify(repository).deleteAllByCategoryId(categoryId);
        inOrder.verify(repository).saveAll(any(List.class));
    }

    @Test
    void recalculate_withoutFinishedGames_savesZeroedRows() {
        UUID categoryId = UUID.randomUUID();
        UUID team1 = UUID.randomUUID();
        UUID team2 = UUID.randomUUID();

        when(teamLookup.findTeamIdsByCategoryId(categoryId))
                .thenReturn(List.of(team1, team2));
        when(gameLookup.findFinishedByCategoryId(categoryId)).thenReturn(List.of());

        service.recalculate(categoryId);

        ArgumentCaptor<List<StandingEntity>> captor = ArgumentCaptor.forClass(List.class);
        verify(repository).saveAll(captor.capture());
        List<StandingEntity> saved = captor.getValue();
        assertThat(saved).hasSize(2);
        saved.forEach(row -> {
            assertThat(row.getCategoryId()).isEqualTo(categoryId);
            assertThat(row.getPlayed()).isZero();
            assertThat(row.getWins()).isZero();
            assertThat(row.getDraws()).isZero();
            assertThat(row.getLosses()).isZero();
            assertThat(row.getGoalsFor()).isZero();
            assertThat(row.getGoalsAgainst()).isZero();
            assertThat(row.getPoints()).isZero();
        });
    }

    @Test
    void recalculate_withoutTeams_onlyDeletes() {
        UUID categoryId = UUID.randomUUID();

        when(teamLookup.findTeamIdsByCategoryId(categoryId)).thenReturn(List.of());

        service.recalculate(categoryId);

        verify(repository).deleteAllByCategoryId(categoryId);
        verify(repository, never()).saveAll(any());
    }

    @Test
    void findByCategoryId_ordersByPointsDescending() {
        UUID categoryId = UUID.randomUUID();
        UUID teamA = UUID.randomUUID();
        UUID teamB = UUID.randomUUID();

        when(repository.findAllByCategoryId(categoryId)).thenReturn(List.of(
                standing(teamB, 0, 1, 1, 2, 3),
                standing(teamA, 2, 0, 0, 6, 1)));
        when(teamLookup.findTeamInfoByCategoryId(categoryId)).thenReturn(List.of(
                new TeamInfo(teamA, "Time A"),
                new TeamInfo(teamB, "Time B")));

        List<StandingResponse> result = service.findByCategoryId(categoryId);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).teamId()).isEqualTo(teamA);
        assertThat(result.get(1).teamId()).isEqualTo(teamB);
        assertThat(result.get(0).points()).isEqualTo(6);
        assertThat(result.get(1).points()).isEqualTo(1);
    }

    @Test
    void findByCategoryId_breaksTieByGoalDifference() {
        UUID categoryId = UUID.randomUUID();
        UUID teamA = UUID.randomUUID();
        UUID teamB = UUID.randomUUID();

        when(repository.findAllByCategoryId(categoryId)).thenReturn(List.of(
                standing(teamA, 2, 0, 0, 4, 3),
                standing(teamB, 2, 0, 0, 5, 1)));
        when(teamLookup.findTeamInfoByCategoryId(categoryId)).thenReturn(List.of(
                new TeamInfo(teamA, "Time A"),
                new TeamInfo(teamB, "Time B")));

        List<StandingResponse> result = service.findByCategoryId(categoryId);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).teamId()).isEqualTo(teamB);
        assertThat(result.get(1).teamId()).isEqualTo(teamA);
        assertThat(result.get(0).points()).isEqualTo(result.get(1).points());
        assertThat(result.get(0).goalDifference()).isEqualTo(4);
        assertThat(result.get(1).goalDifference()).isEqualTo(1);
    }

    @Test
    void findByCategoryId_breaksTieByGoalsFor() {
        UUID categoryId = UUID.randomUUID();
        UUID teamA = UUID.randomUUID();
        UUID teamB = UUID.randomUUID();

        when(repository.findAllByCategoryId(categoryId)).thenReturn(List.of(
                standing(teamA, 2, 0, 0, 3, 0),
                standing(teamB, 2, 0, 0, 4, 1)));
        when(teamLookup.findTeamInfoByCategoryId(categoryId)).thenReturn(List.of(
                new TeamInfo(teamA, "Time A"),
                new TeamInfo(teamB, "Time B")));

        List<StandingResponse> result = service.findByCategoryId(categoryId);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).teamId()).isEqualTo(teamB);
        assertThat(result.get(1).teamId()).isEqualTo(teamA);
        assertThat(result.get(0).points()).isEqualTo(result.get(1).points());
        assertThat(result.get(0).goalDifference()).isEqualTo(result.get(1).goalDifference());
        assertThat(result.get(0).goalsFor()).isEqualTo(4);
        assertThat(result.get(1).goalsFor()).isEqualTo(3);
    }

    @Test
    void findByCategoryId_assignsSequentialPositions_andComputesGoalDifference() {
        UUID categoryId = UUID.randomUUID();
        UUID teamA = UUID.randomUUID();
        UUID teamB = UUID.randomUUID();
        UUID teamC = UUID.randomUUID();

        when(repository.findAllByCategoryId(categoryId)).thenReturn(List.of(
                standing(teamA, 1, 1, 0, 4, 2),
                standing(teamC, 0, 0, 1, 1, 3),
                standing(teamB, 1, 0, 1, 2, 2)));
        when(teamLookup.findTeamInfoByCategoryId(categoryId)).thenReturn(List.of(
                new TeamInfo(teamA, "Time A"),
                new TeamInfo(teamB, "Time B"),
                new TeamInfo(teamC, "Time C")));

        List<StandingResponse> result = service.findByCategoryId(categoryId);

        assertThat(result).hasSize(3);
        assertThat(result).extracting(StandingResponse::position)
                .containsExactly(1, 2, 3);
        assertThat(result).extracting(StandingResponse::teamId)
                .containsExactly(teamA, teamB, teamC);
        assertThat(result.get(0).goalDifference()).isEqualTo(2);
        assertThat(result.get(1).goalDifference()).isZero();
        assertThat(result.get(2).goalDifference()).isEqualTo(-2);
    }

    @Test
    void findByCategoryId_fillsTeamNameFromLookup() {
        UUID categoryId = UUID.randomUUID();
        UUID teamA = UUID.randomUUID();

        when(repository.findAllByCategoryId(categoryId)).thenReturn(List.of(
                standing(teamA, 1, 0, 0, 3, 1)));
        when(teamLookup.findTeamInfoByCategoryId(categoryId)).thenReturn(List.of(
                new TeamInfo(teamA, "Tritões")));

        List<StandingResponse> result = service.findByCategoryId(categoryId);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).teamName()).isEqualTo("Tritões");
    }

    @Test
    void findByCategoryId_teamWithoutNameInLookup_usesEmptyString() {
        UUID categoryId = UUID.randomUUID();
        UUID teamA = UUID.randomUUID();

        when(repository.findAllByCategoryId(categoryId)).thenReturn(List.of(
                standing(teamA, 1, 0, 0, 3, 1)));
        when(teamLookup.findTeamInfoByCategoryId(categoryId)).thenReturn(List.of());

        List<StandingResponse> result = service.findByCategoryId(categoryId);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).teamName()).isEmpty();
    }

    @Test
    void findByCategoryId_withoutStandings_returnsEmptyList() {
        UUID categoryId = UUID.randomUUID();

        when(repository.findAllByCategoryId(categoryId)).thenReturn(List.of());
        when(teamLookup.findTeamInfoByCategoryId(categoryId)).thenReturn(List.of());

        assertThat(service.findByCategoryId(categoryId)).isEmpty();
    }

    private StandingEntity standing(UUID teamId, int wins, int draws, int losses,
                                    int goalsFor, int goalsAgainst) {
        StandingEntity entity = new StandingEntity();
        entity.setTeamId(teamId);
        entity.setPlayed(wins + draws + losses);
        entity.setWins(wins);
        entity.setDraws(draws);
        entity.setLosses(losses);
        entity.setGoalsFor(goalsFor);
        entity.setGoalsAgainst(goalsAgainst);
        entity.setPoints(wins * 3 + draws);
        return entity;
    }

    private StandingEntity findByTeam(List<StandingEntity> rows, UUID teamId) {
        return rows.stream()
                .filter(row -> row.getTeamId().equals(teamId))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Standing not found for team " + teamId));
    }
}
