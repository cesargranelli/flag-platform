package br.com.flagplatform.standing.service;

import br.com.flagplatform.game.FinishedGame;
import br.com.flagplatform.game.GameLookup;
import br.com.flagplatform.standing.dto.response.StandingResponse;
import br.com.flagplatform.standing.entity.StandingEntity;
import br.com.flagplatform.standing.repository.StandingRepository;
import br.com.flagplatform.team.TeamInfo;
import br.com.flagplatform.team.TeamLookup;
import br.com.flagplatform.team.repository.CompetitionTeamRepository;
import br.com.flagplatform.team.repository.TeamRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RequiredArgsConstructor
@Transactional(readOnly = true)
@Service
public class StandingService {

    private final StandingRepository repository;
    private final TeamLookup teamLookup;
    private final GameLookup gameLookup;
    private final CompetitionTeamRepository competitionTeamRepository;
    private final TeamRepository teamRepository;

    /**
     * REQUIRES_NEW é necessário porque o listener roda no afterCommit da transação
     * que registrou o resultado: nesse ponto o Spring ainda considera a transação
     * original "ativa", então um REQUIRED comum apenas participaria dela (já
     * comitada no banco) e o flush nunca aconteceria. Com REQUIRES_NEW o recálculo
     * roda em uma transação própria e realmente persiste.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recalculate(UUID competitionId) {
        List<UUID> teamIds = competitionTeamRepository.findAllByCompetitionIdOrderByCreatedAtAsc(competitionId)
                .stream()
                .map(ct -> ct.getTeamId())
                .toList();
        List<FinishedGame> games = gameLookup.findFinishedByCompetitionId(competitionId);

        repository.deleteAllByCompetitionId(competitionId);

        if (teamIds.isEmpty()) {
            return;
        }

        List<StandingEntity> standings = teamIds.stream()
                .map(teamId -> buildStanding(competitionId, teamId, games))
                .toList();

        repository.saveAll(standings);
    }

    private StandingEntity buildStanding(UUID competitionId, UUID teamId, List<FinishedGame> games) {
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
        entity.setCompetitionId(competitionId);
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

    /**
     * Consulta pública da classificação de uma competição, ordenada por
     * pontos DESC, saldo de gols DESC, gols pró DESC e nome do time ASC
     * (desempate estável).
     */
    public List<StandingResponse> findByCompetitionId(UUID competitionId) {
        Map<UUID, String> teamNames = new HashMap<>();
        List<UUID> teamIds = competitionTeamRepository.findAllByCompetitionIdOrderByCreatedAtAsc(competitionId)
                .stream()
                .map(ct -> ct.getTeamId())
                .toList();
        for (UUID teamId : teamIds) {
            teamRepository.findById(teamId).ifPresent(team ->
                    teamNames.put(teamId, team.getName() == null ? "" : team.getName()));
        }

        List<Entry> entries = repository.findAllByCompetitionId(competitionId).stream()
                .map(row -> new Entry(row, teamNames.getOrDefault(row.getTeamId(), "")))
                .sorted(Comparator
                        .comparingInt(Entry::points).reversed()
                        .thenComparing(Comparator.comparingInt(Entry::goalDifference).reversed())
                        .thenComparing(Comparator.comparingInt(Entry::goalsFor).reversed())
                        .thenComparing(Entry::teamName))
                .toList();

        List<StandingResponse> responses = new ArrayList<>(entries.size());
        for (int i = 0; i < entries.size(); i++) {
            responses.add(entries.get(i).toResponse(i + 1));
        }
        return responses;
    }

    private record Entry(StandingEntity entity, String teamName) {

        int points() {
            return entity.getPoints();
        }

        int goalDifference() {
            return entity.getGoalsFor() - entity.getGoalsAgainst();
        }

        int goalsFor() {
            return entity.getGoalsFor();
        }

        StandingResponse toResponse(int position) {
            return new StandingResponse(
                    position,
                    entity.getTeamId(),
                    teamName,
                    entity.getPlayed(),
                    entity.getWins(),
                    entity.getDraws(),
                    entity.getLosses(),
                    entity.getGoalsFor(),
                    entity.getGoalsAgainst(),
                    goalDifference(),
                    entity.getPoints());
        }
    }
}
