package br.com.flagplatform;

import br.com.flagplatform.athlete.entity.AthleteEntity;
import br.com.flagplatform.athlete.repository.AthleteRepository;
import br.com.flagplatform.common.enums.AgeGroup;
import br.com.flagplatform.common.enums.AthletePosition;
import br.com.flagplatform.common.enums.AthleteStatus;
import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.common.enums.GameStatus;
import br.com.flagplatform.common.enums.Gender;
import br.com.flagplatform.common.enums.GroupingType;
import br.com.flagplatform.common.enums.Modality;
import br.com.flagplatform.common.enums.OrganizationStatus;
import br.com.flagplatform.common.enums.OrganizationType;
import br.com.flagplatform.common.enums.RoundType;
import br.com.flagplatform.common.enums.RosterStatus;
import br.com.flagplatform.competition.entity.CompetitionEntity;
import br.com.flagplatform.competition.repository.CompetitionRepository;
import br.com.flagplatform.game.entity.GameEntity;
import br.com.flagplatform.game.entity.ScoreEventEntity;
import br.com.flagplatform.game.repository.GameRepository;
import br.com.flagplatform.game.repository.ScoreEventRepository;
import br.com.flagplatform.organization.entity.OrganizationEntity;
import br.com.flagplatform.organization.repository.OrganizationRepository;
import br.com.flagplatform.play.entity.PlayEntity;
import br.com.flagplatform.play.entity.PlayType;
import br.com.flagplatform.play.repository.PlayRepository;
import br.com.flagplatform.round.entity.RoundEntity;
import br.com.flagplatform.round.repository.RoundRepository;
import br.com.flagplatform.roster.entity.RosterEntity;
import br.com.flagplatform.roster.entity.RosterEntryEntity;
import br.com.flagplatform.roster.repository.RosterEntryRepository;
import br.com.flagplatform.roster.repository.RosterRepository;
import br.com.flagplatform.standing.entity.StandingEntity;
import br.com.flagplatform.standing.repository.StandingRepository;
import br.com.flagplatform.team.entity.CompetitionTeamEntity;
import br.com.flagplatform.team.entity.TeamEntity;
import br.com.flagplatform.team.repository.CompetitionTeamRepository;
import br.com.flagplatform.team.repository.TeamRepository;
import br.com.flagplatform.venue.entity.VenueEntity;
import br.com.flagplatform.venue.repository.VenueRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Seeder de dados demo para o Flag Platform.
 * <p>
 * Cria dados realistas de flag football (organizações, competições, times,
 * rodadas, jogos, placar, classificação, atletas e rosters).
 * Somente executa com o profile {@code demo} ({@code --spring.profiles.active=demo}).
 * <p>
 * Idempotente: verifica se a organização com o trade name "LNFF" já existe
 * antes de criar qualquer dado.
 */
@Slf4j
@RequiredArgsConstructor
@Component
@Profile("demo")
public class DemoDataSeeder implements CommandLineRunner {

    private final OrganizationRepository organizationRepository;
    private final VenueRepository venueRepository;
    private final CompetitionRepository competitionRepository;
    private final TeamRepository teamRepository;
    private final CompetitionTeamRepository competitionTeamRepository;
    private final RoundRepository roundRepository;
    private final GameRepository gameRepository;
    private final ScoreEventRepository scoreEventRepository;
    private final StandingRepository standingRepository;
    private final AthleteRepository athleteRepository;
    private final RosterRepository rosterRepository;
    private final RosterEntryRepository rosterEntryRepository;
    private final PlayRepository playRepository;

    @Override
    @Transactional
    public void run(String... args) {
        if (organizationRepository.existsByTradeNameIgnoreCase("LNFF")) {
            log.info("Dados demo já existem — ignorando seed.");
            return;
        }

        log.info("=== Iniciando seed de dados demo ===");

        OrganizationEntity org = createOrganization();
        List<VenueEntity> venues = createVenues(org);
        CompetitionEntity comp1 = createCompetition1(org);
        CompetitionEntity comp2 = createCompetition2(org);
        List<TeamEntity> teams1 = createTeamsComp1(org, comp1);
        List<TeamEntity> teams2 = createTeamsComp2(org, comp2);
        List<RoundEntity> rounds1 = createRounds(comp1);
        List<RoundEntity> rounds2 = createRounds(comp2);
        List<GameEntity> games1 = createGames(rounds1, teams1, venues);
        List<GameEntity> games2 = createGames(rounds2, teams2, venues);
        createScoreEventsForFinishedGames(games1);
        createScoreEventsForFinishedGames(games2);
        createPlaysForGames(games1, teams1);
        createPlaysForGames(games2, teams2);
        createStandings(comp1, teams1, games1);
        createStandings(comp2, teams2, games2);
        createAthletesAndRosters(teams1, comp1);
        createAthletesAndRosters(teams2, comp2);

        log.info("=== Seed de dados demo concluído ===");
    }

    // ── Organization ──────────────────────────────────────────────────────

    private OrganizationEntity createOrganization() {
        OrganizationEntity org = new OrganizationEntity();
        org.setLegalName("Liga Nacional de Flag Football");
        org.setTradeName("LNFF");
        org.setAbbreviation("LNFF");
        org.setOrganizationType(OrganizationType.LEAGUE);
        org.setDocument("12.345.678/0001-90");
        org.setDocumentType(br.com.flagplatform.common.enums.DocumentType.CNPJ);
        org.setPresidentName("João Silva");
        org.setEmail("contato@lnff.com.br");
        org.setPhone("+55 11 99999-0000");
        org.setCountry("BR");
        org.setState("SP");
        org.setCity("São Paulo");
        org.setPrimaryColor("#1E3A5F");
        org.setSecondaryColor("#C8102E");
        org.setTimezone("America/Sao_Paulo");
        org.setLocale("pt-BR");
        org.setStatus(OrganizationStatus.ACTIVE);
        organizationRepository.save(org);
        log.info("Organização criada: {}", org.getTradeName());
        return org;
    }

    // ── Venues ────────────────────────────────────────────────────────────

    private List<VenueEntity> createVenues(OrganizationEntity org) {
        List<VenueEntity> venues = new ArrayList<>();

        VenueEntity v1 = new VenueEntity();
        v1.setOrganizationId(org.getId());
        v1.setName("Campo Central");
        v1.setAddress("Rua dos Esportes, 100 - São Paulo, SP");
        venueRepository.save(v1);
        venues.add(v1);

        VenueEntity v2 = new VenueEntity();
        v2.setOrganizationId(org.getId());
        v2.setName("Campo Norte");
        v2.setAddress("Av. Atlântica, 200 - Guarulhos, SP");
        venueRepository.save(v2);
        venues.add(v2);

        log.info("Venues criados: {}", venues.stream().map(VenueEntity::getName).toList());
        return venues;
    }

    // ── Competitions ──────────────────────────────────────────────────────

    private CompetitionEntity createCompetition1(OrganizationEntity org) {
        CompetitionEntity comp = new CompetitionEntity();
        comp.setOrganizationId(org.getId());
        comp.setModality(Modality.FLAG_5X5);
        comp.setGender(Gender.MALE);
        comp.setAgeGroup(AgeGroup.ADULT);
        comp.setName("Copa Brasil Flag 2026");
        comp.setDescription("Campeonato nacional masculino de flag football 5x5");
        comp.setStartDate(LocalDate.of(2026, 3, 1));
        comp.setEndDate(LocalDate.of(2026, 8, 30));
        comp.setStatus(CompetitionStatus.PUBLISHED);
        comp.setGroupingType(GroupingType.GROUPS);
        comp.setSeason("2026");
        competitionRepository.save(comp);
        log.info("Competição criada: {}", comp.getName());
        return comp;
    }

    private CompetitionEntity createCompetition2(OrganizationEntity org) {
        CompetitionEntity comp = new CompetitionEntity();
        comp.setOrganizationId(org.getId());
        comp.setModality(Modality.FLAG_5X5);
        comp.setGender(Gender.FEMALE);
        comp.setAgeGroup(AgeGroup.ADULT);
        comp.setName("Liga Regional Feminina");
        comp.setDescription("Liga regional feminina de flag football 5x5");
        comp.setStartDate(LocalDate.of(2026, 4, 1));
        comp.setEndDate(LocalDate.of(2026, 9, 15));
        comp.setStatus(CompetitionStatus.PUBLISHED);
        comp.setGroupingType(GroupingType.GROUPS);
        comp.setSeason("2026");
        competitionRepository.save(comp);
        log.info("Competição criada: {}", comp.getName());
        return comp;
    }

    // ── Teams ─────────────────────────────────────────────────────────────

    private List<TeamEntity> createTeamsComp1(OrganizationEntity org, CompetitionEntity comp) {
        String[] names = {"Tigers", "Lynx", "Eagles", "Hawks"};
        String[] shortNames = {"TIG", "LYN", "EAG", "HAW"};
        List<TeamEntity> teams = new ArrayList<>();
        for (int i = 0; i < names.length; i++) {
            TeamEntity t = new TeamEntity();
            t.setOrganizationId(org.getId());
            t.setName(names[i]);
            t.setShortName(shortNames[i]);
            t.setStatus(OrganizationStatus.ACTIVE);
            teamRepository.save(t);
            teams.add(t);

            // Inscrever time na competição
            CompetitionTeamEntity ct = new CompetitionTeamEntity();
            ct.setCompetitionId(comp.getId());
            ct.setTeamId(t.getId());
            competitionTeamRepository.save(ct);
        }
        log.info("Times Copa Brasil criados: {}", teams.stream().map(TeamEntity::getName).toList());
        return teams;
    }

    private List<TeamEntity> createTeamsComp2(OrganizationEntity org, CompetitionEntity comp) {
        String[] names = {"Wolves", "Bears", "Falcons", "Panthers"};
        String[] shortNames = {"WOL", "BEA", "FAL", "PAN"};
        List<TeamEntity> teams = new ArrayList<>();
        for (int i = 0; i < names.length; i++) {
            TeamEntity t = new TeamEntity();
            t.setOrganizationId(org.getId());
            t.setName(names[i]);
            t.setShortName(shortNames[i]);
            t.setStatus(OrganizationStatus.ACTIVE);
            teamRepository.save(t);
            teams.add(t);

            // Inscrever time na competição
            CompetitionTeamEntity ct = new CompetitionTeamEntity();
            ct.setCompetitionId(comp.getId());
            ct.setTeamId(t.getId());
            competitionTeamRepository.save(ct);
        }
        log.info("Times Liga Regional criados: {}", teams.stream().map(TeamEntity::getName).toList());
        return teams;
    }

    // ── Rounds ────────────────────────────────────────────────────────────

    private List<RoundEntity> createRounds(CompetitionEntity comp) {
        List<RoundEntity> rounds = new ArrayList<>();
        for (int i = 1; i <= 3; i++) {
            RoundEntity r = new RoundEntity();
            r.setCompetitionId(comp.getId());
            r.setNumber(i);
            r.setName("Rodada " + i);
            r.setType(RoundType.REGULAR);
            roundRepository.save(r);
            rounds.add(r);
        }
        log.info("Rodadas criadas para {}: {}", comp.getName(),
                rounds.stream().map(RoundEntity::getNumber).toList());
        return rounds;
    }

    // ── Games ─────────────────────────────────────────────────────────────

    /**
     * Cria 2 jogos por rodada (round-robin parcial com 4 times → 2 jogos por rodada).
     * <p>
     * Rodada 1: FINISHED (passado, com placar)
     * Rodada 2: IN_PROGRESS (agora)
     * Rodada 3: SCHEDULED (futuro)
     */
    private List<GameEntity> createGames(List<RoundEntity> rounds,
                                         List<TeamEntity> teams,
                                         List<VenueEntity> venues) {
        List<GameEntity> games = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();

        // Round 1 — FINISHED (7 dias atrás)
        games.add(createGame(rounds.get(0), teams.get(0), teams.get(1),
                venues.get(0), GameStatus.FINISHED, now.minusDays(7), 24, 18));
        games.add(createGame(rounds.get(0), teams.get(2), teams.get(3),
                venues.get(1), GameStatus.FINISHED, now.minusDays(7), 12, 20));

        // Round 2 — IN_PROGRESS (hoje)
        games.add(createGame(rounds.get(1), teams.get(0), teams.get(2),
                venues.get(0), GameStatus.IN_PROGRESS, now.minusMinutes(30), null, null));
        games.add(createGame(rounds.get(1), teams.get(1), teams.get(3),
                venues.get(1), GameStatus.IN_PROGRESS, now.minusMinutes(15), null, null));

        // Round 3 — SCHEDULED (7 dias no futuro)
        games.add(createGame(rounds.get(2), teams.get(0), teams.get(3),
                venues.get(0), GameStatus.SCHEDULED, now.plusDays(7), null, null));
        games.add(createGame(rounds.get(2), teams.get(1), teams.get(2),
                venues.get(1), GameStatus.SCHEDULED, now.plusDays(7), null, null));

        log.info("Jogos criados: {} ({} finished, {} in_progress, {} scheduled)",
                games.size(), 2, 2, 2);
        return games;
    }

    private GameEntity createGame(RoundEntity round,
                                  TeamEntity home, TeamEntity away,
                                  VenueEntity venue,
                                  GameStatus status,
                                  LocalDateTime scheduledAt,
                                  Integer homeScore, Integer awayScore) {
        GameEntity g = new GameEntity();
        g.setRoundId(round.getId());
        g.setHomeTeamId(home.getId());
        g.setAwayTeamId(away.getId());
        g.setVenueId(venue.getId());
        g.setScheduledAt(scheduledAt);
        g.setStatus(status);
        g.setHomeScore(homeScore);
        g.setAwayScore(awayScore);
        gameRepository.save(g);
        return g;
    }

    // ── Score Events ──────────────────────────────────────────────────────

    /**
     * Cria 3 a 5 eventos de placar por jogo finalizado, usando as duas equipes.
     */
    private void createScoreEventsForFinishedGames(List<GameEntity> games) {
        int total = 0;
        for (GameEntity g : games) {
            if (g.getStatus() != GameStatus.FINISHED) {
                continue;
            }
            List<ScoreEventEntity> events = new ArrayList<>();
            // Interleave scores between home and away based on final score
            int homePts = g.getHomeScore() != null ? g.getHomeScore() : 0;
            int awayPts = g.getAwayScore() != null ? g.getAwayScore() : 0;

            // Simulate a few scoring plays
            int[] homePoints = distributePoints(homePts);
            int[] awayPoints = distributePoints(awayPts);

            LocalDateTime base = g.getScheduledAt();
            int minute = 1;
            for (int i = 0; i < Math.max(homePoints.length, awayPoints.length); i++) {
                if (i < homePoints.length) {
                    events.add(createScoreEvent(g.getId(), g.getHomeTeamId(), base.plusMinutes(minute)));
                    minute += 5;
                }
                if (i < awayPoints.length) {
                    events.add(createScoreEvent(g.getId(), g.getAwayTeamId(), base.plusMinutes(minute)));
                    minute += 5;
                }
            }

            scoreEventRepository.saveAll(events);
            total += events.size();
        }
        log.info("Score events criados: {}", total);
    }

    /**
     * Distribui pontos totais em jogadas de 6 (TD) e 3 (field goal).
     */
    private int[] distributePoints(int totalPoints) {
        List<Integer> plays = new ArrayList<>();
        int remaining = totalPoints;
        while (remaining >= 6) {
            plays.add(6);
            remaining -= 6;
        }
        if (remaining >= 3) {
            plays.add(3);
            remaining -= 3;
        }
        if (remaining > 0) {
            plays.add(remaining);
        }
        return plays.stream().mapToInt(Integer::intValue).toArray();
    }

    private ScoreEventEntity createScoreEvent(UUID gameId, UUID teamId, LocalDateTime createdAt) {
        ScoreEventEntity e = new ScoreEventEntity();
        e.setGameId(gameId);
        e.setTeamId(teamId);
        return e;
    }

    // ── Standings ─────────────────────────────────────────────────────────

    private void createStandings(CompetitionEntity comp,
                                 List<TeamEntity> teams,
                                 List<GameEntity> games) {
        // Calculate standings from finished games
        java.util.Map<UUID, int[]> stats = new java.util.LinkedHashMap<>();
        for (TeamEntity t : teams) {
            stats.put(t.getId(), new int[]{0, 0, 0, 0, 0, 0, 0}); // played, wins, draws, losses, gf, ga, pts
        }

        for (GameEntity g : games) {
            if (g.getStatus() != GameStatus.FINISHED) {
                continue;
            }
            int hs = g.getHomeScore() != null ? g.getHomeScore() : 0;
            int as = g.getAwayScore() != null ? g.getAwayScore() : 0;

            int[] home = stats.get(g.getHomeTeamId());
            int[] away = stats.get(g.getAwayTeamId());

            home[0]++; away[0]++; // played
            home[4] += hs; home[5] += as; // gf, ga
            away[4] += as; away[5] += hs;

            if (hs > as) {
                home[1]++; home[6] += 3; // win + 3pts
                away[3]++;               // loss
            } else if (hs < as) {
                away[1]++; away[6] += 3;
                home[3]++;
            } else {
                home[2]++; away[2]++; // draw
                home[6] += 1; away[6] += 1;
            }
        }

        for (TeamEntity t : teams) {
            int[] s = stats.get(t.getId());
            StandingEntity st = new StandingEntity();
            st.setCompetitionId(comp.getId());
            st.setTeamId(t.getId());
            st.setPlayed(s[0]);
            st.setWins(s[1]);
            st.setDraws(s[2]);
            st.setLosses(s[3]);
            st.setGoalsFor(s[4]);
            st.setGoalsAgainst(s[5]);
            st.setPoints(s[6]);
            standingRepository.save(st);
        }

        log.info("Standings criados para {}: {} times", comp.getName(), teams.size());
    }

    // ── Athletes & Rosters ────────────────────────────────────────────────

    private void createAthletesAndRosters(List<TeamEntity> teams, CompetitionEntity comp) {
        AthletePosition[][] positionSets = {
                {AthletePosition.QB, AthletePosition.WR},
                {AthletePosition.RB, AthletePosition.WR},
                {AthletePosition.WR, AthletePosition.DB},
                {AthletePosition.LB, AthletePosition.DB},
                {AthletePosition.QB, AthletePosition.RB},
                {AthletePosition.TE, AthletePosition.LB},
                {AthletePosition.WR, AthletePosition.C},
                {AthletePosition.DL, AthletePosition.DB}
        };

        int athleteCounter = 0;
        for (TeamEntity team : teams) {
            // Criar roster para o time na competição
            RosterEntity roster = new RosterEntity();
            roster.setTeamId(team.getId());
            roster.setCompetitionId(comp.getId());
            roster.setName("Elenco " + team.getName() + " " + comp.getSeason());
            roster.setSeason(comp.getSeason());
            roster.setStatus(RosterStatus.ACTIVE);
            rosterRepository.save(roster);

            // 5 athletes per team (flag 5x5)
            for (int i = 0; i < 5; i++) {
                int idx = athleteCounter % positionSets.length;
                String name = "Atleta " + (athleteCounter + 1);
                String cpf = generateCpf(athleteCounter);

                if (athleteRepository.existsByCpf(cpf)) {
                    continue;
                }

                AthleteEntity a = new AthleteEntity();
                a.setName(name);
                a.setCpf(cpf);
                a.setNickname("Nick" + (athleteCounter + 1));
                a.setNumber((athleteCounter % 99) + 1);
                a.setPositions(java.util.Arrays.asList(positionSets[idx]));
                a.setStatus(AthleteStatus.ACTIVE);
                athleteRepository.save(a);

                if (!rosterEntryRepository.existsByRosterIdAndAthleteId(roster.getId(), a.getId())) {
                    RosterEntryEntity re = new RosterEntryEntity();
                    re.setRosterId(roster.getId());
                    re.setAthleteId(a.getId());
                    re.setStatus(RosterStatus.ACTIVE);
                    re.setNumber(a.getNumber());
                    re.setNickname(a.getNickname());
                    rosterEntryRepository.save(re);
                }

                athleteCounter++;
            }
        }
        log.info("Atletas criados: {}, Rosters criados para {} times", athleteCounter, teams.size());
    }

    // ── Plays (Play-by-Play) ───────────────────────────────────────────────

    private void createPlaysForGames(List<GameEntity> games, List<TeamEntity> teams) {
        String[][] playerNames = {
            {"Carlos Silva", "Pedro Costa", "Lucas Ferreira", "Gabriel Oliveira", "André Mendes"},
            {"Rafael Santos", "Matheus Almeida", "Bruno Costa", "Felipe Lima", "Thiago Souza"}
        };

        String[][] receiverNames = {
            {"Pedro Costa", "Gabriel Oliveira", "Lucas Ferreira", "Carlos Silva", "Rafael Santos"},
            {"Matheus Almeida", "Bruno Costa", "Felipe Lima", "Thiago Souza", "André Mendes"}
        };

        PlayType[][] playTypes = {
            {PlayType.PASS, PlayType.RUN, PlayType.PASS, PlayType.TOUCHDOWN, PlayType.INTERCEPTION},
            {PlayType.RUN, PlayType.PASS, PlayType.RUN, PlayType.FIRST_DOWN, PlayType.PASS}
        };

        int[][] yardsValues = {
            {12, 5, 8, 25, 0},
            {3, 15, 7, 10, 20}
        };

        String[] quarters = {"Q1", "Q2", "Q3", "Q4"};
        String[] times = {"12:00", "08:32", "05:15", "02:48", "00:30"};

        int playCount = 0;
        for (GameEntity game : games) {
            if (playRepository.existsByGameId(game.getId())) {
                continue;
            }

            TeamEntity homeTeam = teams.stream()
                .filter(t -> t.getId().equals(game.getHomeTeamId()))
                .findFirst().orElse(teams.get(0));
            TeamEntity awayTeam = teams.stream()
                .filter(t -> t.getId().equals(game.getAwayTeamId()))
                .findFirst().orElse(teams.get(1));

            for (int q = 0; q < 2; q++) {
                for (int p = 0; p < 3; p++) {
                    boolean isHome = (q + p) % 2 == 0;
                    TeamEntity team = isHome ? homeTeam : awayTeam;
                    int teamIdx = isHome ? 0 : 1;
                    int playIdx = p % playTypes[teamIdx].length;

                    PlayEntity play = new PlayEntity();
                    play.setGameId(game.getId());
                    play.setTeamId(team.getId());
                    play.setPlayerName(playerNames[teamIdx][playIdx]);
                    play.setReceiverName(receiverNames[teamIdx][playIdx]);
                    play.setPlayType(playTypes[teamIdx][playIdx]);
                    play.setYards(yardsValues[teamIdx][playIdx]);
                    play.setQuarter(quarters[q]);
                    play.setTime(times[p]);
                    play.setIsFirstDown(playTypes[teamIdx][playIdx] == PlayType.FIRST_DOWN);
                    play.setIsTouchdown(playTypes[teamIdx][playIdx] == PlayType.TOUCHDOWN);
                    play.setIsTurnover(playTypes[teamIdx][playIdx] == PlayType.INTERCEPTION);

                    String desc = buildPlayDescription(play);
                    play.setDescription(desc);

                    playRepository.save(play);
                    playCount++;
                }
            }
        }
        log.info("Plays criados: {} lances para {} jogos", playCount, games.size());
    }

    private String buildPlayDescription(PlayEntity play) {
        return switch (play.getPlayType()) {
            case PASS -> play.getPlayerName() + " passe completo, " +
                (play.getReceiverName() != null ? play.getReceiverName() + " recepção → " : "→ ") +
                play.getYards() + " jds";
            case RUN -> play.getPlayerName() + " corrida → " + play.getYards() + " jds";
            case TOUCHDOWN -> play.getPlayerName() + " passe, " +
                (play.getReceiverName() != null ? play.getReceiverName() + " " : "") +
                "touchdown! → " + play.getYards() + " jds";
            case INTERCEPTION -> play.getPlayerName() + " interceptação!";
            case FIELD_GOAL -> play.getPlayerName() + " field goal → " + play.getYards() + " jds";
            case PUNT -> play.getPlayerName() + " punt → " + play.getYards() + " jds";
            case KICKOFF -> play.getPlayerName() + " kickoff";
            case PENALTY -> play.getPlayerName() + " penalidade";
            case FIRST_DOWN -> play.getPlayerName() + " first down → " + play.getYards() + " jds";
        };
    }

    /**
     * Gera um CPF fictício único baseado em um contador (formato XXX.XXX.XXX-XX).
     */
    private String generateCpf(int seed) {
        int base = 100_000_000 + (seed * 7 + 3) % 900_000_000;
        String digits = String.valueOf(base).substring(0, 9);
        // Simple check digits
        int d1 = 0;
        for (int i = 0; i < 9; i++) {
            d1 += (digits.charAt(i) - '0') * (10 - i);
        }
        d1 = 11 - (d1 % 11);
        if (d1 >= 10) d1 = 0;
        int d2 = 0;
        for (int i = 0; i < 9; i++) {
            d2 += (digits.charAt(i) - '0') * (11 - i);
        }
        d2 += d1 * 2;
        d2 = 11 - (d2 % 11);
        if (d2 >= 10) d2 = 0;
        return digits + d1 + d2;
    }
}
