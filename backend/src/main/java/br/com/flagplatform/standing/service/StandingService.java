package br.com.flagplatform.standing.service;

import br.com.flagplatform.game.FinishedGame;
import br.com.flagplatform.game.GameLookup;
import br.com.flagplatform.standing.entity.StandingEntity;
import br.com.flagplatform.standing.repository.StandingRepository;
import br.com.flagplatform.team.TeamLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class StandingService {

    private final StandingRepository repository;
    private final TeamLookup teamLookup;
    private final GameLookup gameLookup;

    /**
     * REQUIRES_NEW é necessário porque o listener roda no afterCommit da transação
     * que registrou o resultado: nesse ponto o Spring ainda considera a transação
     * original "ativa", então um REQUIRED comum apenas participaria dela (já
     * comitada no banco) e o flush nunca aconteceria. Com REQUIRES_NEW o recálculo
     * roda em uma transação própria e realmente persiste.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recalculate(UUID categoryId) {
        List<UUID> teamIds = teamLookup.findTeamIdsByCategoryId(categoryId);
        List<FinishedGame> games = gameLookup.findFinishedByCategoryId(categoryId);

        repository.deleteAllByCategoryId(categoryId);

        if (teamIds.isEmpty()) {
            return;
        }

        List<StandingEntity> standings = teamIds.stream()
                .map(teamId -> buildStanding(categoryId, teamId, games))
                .toList();

        repository.saveAll(standings);
    }

    private StandingEntity buildStanding(UUID categoryId, UUID teamId, List<FinishedGame> games) {
        int played = 0;
        int wins = 0;
        int draws = 0;
        int losses = 0;
        int goalsFor = 0;
        int goalsAgainst = 0;

        for (FinishedGame game : games) {
            if (game.homeTeamId().equals(teamId)) {
                played++;
                goalsFor += game.homeScore();
                goalsAgainst += game.awayScore();
                wins += game.homeScore() > game.awayScore() ? 1 : 0;
                draws += game.homeScore() == game.awayScore() ? 1 : 0;
                losses += game.homeScore() < game.awayScore() ? 1 : 0;
            } else if (game.awayTeamId().equals(teamId)) {
                played++;
                goalsFor += game.awayScore();
                goalsAgainst += game.homeScore();
                wins += game.awayScore() > game.homeScore() ? 1 : 0;
                draws += game.awayScore() == game.homeScore() ? 1 : 0;
                losses += game.awayScore() < game.homeScore() ? 1 : 0;
            }
        }

        StandingEntity entity = new StandingEntity();
        entity.setCategoryId(categoryId);
        entity.setTeamId(teamId);
        entity.setPlayed(played);
        entity.setWins(wins);
        entity.setDraws(draws);
        entity.setLosses(losses);
        entity.setGoalsFor(goalsFor);
        entity.setGoalsAgainst(goalsAgainst);
        entity.setPoints(wins * 3 + draws * 1);
        return entity;
    }
}
