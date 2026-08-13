package br.com.flagplatform.standing.service;

import br.com.flagplatform.game.FinishedGame;
import br.com.flagplatform.game.GameLookup;
import br.com.flagplatform.standing.entity.StandingEntity;
import br.com.flagplatform.standing.repository.StandingRepository;
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

    private StandingEntity findByTeam(List<StandingEntity> rows, UUID teamId) {
        return rows.stream()
                .filter(row -> row.getTeamId().equals(teamId))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Standing not found for team " + teamId));
    }
}
