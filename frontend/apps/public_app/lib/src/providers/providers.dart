import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Um campeonato "em foco": o que o torcedor escolheu para acompanhar.
///
/// Só o par `id`/`name` é retido (o restante vem dos providers de dados).
typedef FocusedCompetition = ({String id, String name});

/// Chave persistida do id do campeonato em foco (SharedPreferences).
const _focusedCompetitionIdKey = 'public_focused_competition_id';

/// Chave persistida do nome do campeonato em foco (SharedPreferences).
const _focusedCompetitionNameKey = 'public_focused_competition_name';

/// Notifier do campeonato em foco, persistido em [SharedPreferences].
///
/// O estado inicial pode ser semeado no `main` via [seedFocusedCompetition]
/// (override do provider) para evitar um instante de "sem foco" no boot;
/// [set] persiste e notifica. Consumidores usam
/// `ref.watch(focusedCompetitionProvider)` para ler o valor.
class FocusedCompetitionNotifier extends Notifier<FocusedCompetition?> {
  FocusedCompetitionNotifier({FocusedCompetition? initial}) : _initial = initial;

  final FocusedCompetition? _initial;

  @override
  FocusedCompetition? build() => _initial;

  /// Define (ou limpa, com `null`) o campeonato em foco e persiste.
  Future<void> set(FocusedCompetition? value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_focusedCompetitionIdKey);
      await prefs.remove(_focusedCompetitionNameKey);
      return;
    }
    await prefs.setString(_focusedCompetitionIdKey, value.id);
    await prefs.setString(_focusedCompetitionNameKey, value.name);
  }
}

/// Provider do campeonato em foco (persistente).
final focusedCompetitionProvider =
    NotifierProvider<FocusedCompetitionNotifier, FocusedCompetition?>(
      FocusedCompetitionNotifier.new,
    );

/// Lê o campeonato em foco persistido, para semear o provider no `main`.
FocusedCompetition? seedFocusedCompetition(SharedPreferences prefs) {
  final id = prefs.getString(_focusedCompetitionIdKey);
  final name = prefs.getString(_focusedCompetitionNameKey);
  if (id == null || id.isEmpty || name == null || name.isEmpty) return null;
  return (id: id, name: name);
}

/// Gerenciador de sessão do app público.
///
/// O Public App não tem login: o token fica nulo e as chamadas são feitas
/// sem cabeçalho de autenticação. Sobrescreva em testes se necessário.
final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(),
);

/// Cliente HTTP da API REST (injeção de dependência padrão da aplicação).
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(session: ref.watch(sessionManagerProvider)),
);

/// Serviço de campeonatos.
final competitionApiProvider = Provider<CompetitionApi>(
  (ref) => CompetitionApi(ref.watch(apiClientProvider)),
);

/// Lista de campeonatos exibida na tela inicial.
final competitionsProvider = FutureProvider<List<Competition>>(
  (ref) => ref.watch(competitionApiProvider).listAll(),
);

// ---------------------------------------------------------------------------
// Fake providers — dados mock para Resultados e Classificação (issue #26/#27)
// ---------------------------------------------------------------------------

/// Jogos encerrados FAKE de uma competição (para a tela Resultados).
///
/// Retorna 8 jogos finalizados com placares variados, ignorando o
/// `competitionId` real (demonstração sem backend).
final fakeCompetitionResultsProvider =
    FutureProvider.family<List<Game>, String>((ref, competitionId) async {
  await Future.delayed(const Duration(milliseconds: 200));
  final now = DateTime.now();

  Game finished({
    required String id,
    required String home,
    required String away,
    required int homeScore,
    required int awayScore,
    required int round,
    required Duration ago,
    String venue = 'Campo Central',
  }) {
    return Game(
      id: 'res-$id',
      roundId: 'round-$round',
      competitionId: competitionId,
      roundNumber: round,
      homeTeamId: 'team-$id-h',
      awayTeamId: 'team-$id-a',
      homeTeamName: home,
      awayTeamName: away,
      venueId: 'venue-$id',
      venueName: venue,
      scheduledAt: now.subtract(ago),
      status: GameStatus.finished,
      homeScore: homeScore,
      awayScore: awayScore,
    );
  }

  return [
    finished(id: '1', home: 'Tigers', away: 'Lynx', homeScore: 28, awayScore: 21, round: 1, ago: const Duration(days: 6)),
    finished(id: '2', home: 'Eagles', away: 'Hawks', homeScore: 14, awayScore: 14, round: 1, ago: const Duration(days: 6, hours: 3), venue: 'Campo Norte'),
    finished(id: '3', home: 'Sharks', away: 'Dolphins', homeScore: 35, awayScore: 7, round: 2, ago: const Duration(days: 5)),
    finished(id: '4', home: 'Wolves', away: 'Bears', homeScore: 21, awayScore: 28, round: 2, ago: const Duration(days: 5, hours: 2), venue: 'Campo Sul'),
    finished(id: '5', home: 'Falcons', away: 'Panthers', homeScore: 42, awayScore: 14, round: 3, ago: const Duration(days: 4)),
    finished(id: '6', home: 'Lions', away: 'Tigers', homeScore: 7, awayScore: 21, round: 3, ago: const Duration(days: 4, hours: 1), venue: 'Campo Leste'),
    finished(id: '7', home: 'Hawks', away: 'Sharks', homeScore: 14, awayScore: 35, round: 4, ago: const Duration(days: 3)),
    finished(id: '8', home: 'Dolphins', away: 'Eagles', homeScore: 21, awayScore: 0, round: 4, ago: const Duration(days: 3, hours: 2), venue: 'Campo Norte'),
  ];
});

/// Tabela de classificação FAKE de uma competição (para a tela Classificação).
///
/// Retorna 8 posições com dados consistentes, ignorando o `competitionId`
/// real (demonstração sem backend).
final fakeCompetitionStandingsProvider =
    FutureProvider.family<List<Standing>, String>((ref, competitionId) async {
  await Future.delayed(const Duration(milliseconds: 200));

  return const [
    Standing(position: 1, teamId: 'team-1', teamName: 'Sharks', played: 4, wins: 3, draws: 0, losses: 1, goalsFor: 70, goalsAgainst: 28, goalDifference: 42, points: 9),
    Standing(position: 2, teamId: 'team-2', teamName: 'Tigers', played: 4, wins: 3, draws: 0, losses: 1, goalsFor: 56, goalsAgainst: 49, goalDifference: 7, points: 9),
    Standing(position: 3, teamId: 'team-3', teamName: 'Dolphins', played: 4, wins: 2, draws: 1, losses: 1, goalsFor: 42, goalsAgainst: 35, goalDifference: 7, points: 7),
    Standing(position: 4, teamId: 'team-4', teamName: 'Wolves', played: 4, wins: 2, draws: 0, losses: 2, goalsFor: 49, goalsAgainst: 42, goalDifference: 7, points: 6),
    Standing(position: 5, teamId: 'team-5', teamName: 'Eagles', played: 4, wins: 1, draws: 1, losses: 2, goalsFor: 28, goalsAgainst: 35, goalDifference: -7, points: 4),
    Standing(position: 6, teamId: 'team-6', teamName: 'Hawks', played: 4, wins: 1, draws: 1, losses: 2, goalsFor: 28, goalsAgainst: 56, goalDifference: -28, points: 4),
    Standing(position: 7, teamId: 'team-7', teamName: 'Lynx', played: 4, wins: 1, draws: 0, losses: 3, goalsFor: 21, goalsAgainst: 49, goalDifference: -28, points: 3),
    Standing(position: 8, teamId: 'team-8', teamName: 'Bears', played: 4, wins: 0, draws: 1, losses: 3, goalsFor: 21, goalsAgainst: 70, goalDifference: -49, points: 1),
  ];
});

/// Serviço de jogos.
final gameApiProvider = Provider<GameApi>(
  (ref) => GameApi(ref.watch(apiClientProvider)),
);

/// Jogos (calendário) de uma competição, ordenados por data.
final competitionGamesProvider = FutureProvider.family<List<Game>, String>(
  (ref, competitionId) =>
      ref.watch(gameApiProvider).listByCompetition(competitionId),
);

/// Detalhe de um jogo por id.
final gameDetailProvider = FutureProvider.family<Game, String>(
  (ref, gameId) => ref.watch(gameApiProvider).getById(gameId),
);

/// Eventos de pontuação (timeline) de um jogo.
final gameScoreEventsProvider = FutureProvider.family<List<ScoreEvent>, String>(
  (ref, gameId) => ref.watch(gameApiProvider).listScoreEvents(gameId),
);

/// Serviço de classificação.
final standingApiProvider = Provider<StandingApi>(
  (ref) => StandingApi(ref.watch(apiClientProvider)),
);

/// Tabela de classificação de um campeonato (fluxo único, sem categorias).
final competitionStandingsProvider =
    FutureProvider.family<List<Standing>, String>(
      (ref, competitionId) =>
          ref.watch(standingApiProvider).listByCompetition(competitionId),
    );

/// Serviço de times.
final teamApiProvider = Provider<TeamApi>(
  (ref) => TeamApi(ref.watch(apiClientProvider)),
);

/// Detalhe público de um time por id (`GET /api/v1/teams/{id}`).
final teamDetailProvider = FutureProvider.family<Team, String>(
  (ref, teamId) => ref.watch(teamApiProvider).getById(teamId),
);

/// Serviço de elencos (roster) de times.
final rosterApiProvider = Provider<RosterApi>(
  (ref) => RosterApi(ref.watch(apiClientProvider)),
);

/// Elenco público de um time (`GET /api/v1/teams/{teamId}/roster`).
final teamRosterProvider = FutureProvider.family<List<RosterEntry>, String>(
  (ref, teamId) => ref.watch(rosterApiProvider).listByTeam(teamId),
);

/// Jogo enriquecido para a tela Ao vivo (com metadados de filtro).
class LiveGame {
  final Game game;
  final String competitionName;
  final Modality modality;
  final Gender gender;

  const LiveGame({
    required this.game,
    required this.competitionName,
    required this.modality,
    required this.gender,
  });
}

/// Jogos ao vivo reais, consumindo `GET /api/v1/games/live`.
final liveGamesProvider = FutureProvider<List<LiveGame>>((ref) async {
  final responses = await ref.watch(gameApiProvider).findLiveGames();
  return responses
      .map(
        (r) => LiveGame(
          game: Game(
            id: r.id,
            roundId: r.roundId ?? '',
            competitionId: r.competitionId,
            roundNumber: r.roundNumber,
            homeTeamName: r.homeTeamName,
            awayTeamName: r.awayTeamName,
            venueId: r.venueId,
            venueName: r.venueName,
            venueAddress: r.venueAddress,
            venueMapsUrl: r.venueMapsUrl,
            scheduledAt: r.scheduledAt,
            status: GameStatus.fromJson(r.status),
            homeScore: r.homeScore,
            awayScore: r.awayScore,
          ),
          competitionName: r.competitionName ?? '',
          modality: Modality.fromJson(r.modality ?? 'FLAG_5X5'),
          gender: Gender.fromJson(r.gender ?? 'MALE'),
        ),
      )
      .toList();
});

/// Filtro ativo na tela Ao vivo.
enum LiveFilter { all, competition, modality, gender }

/// Tipo de lance de futebol americano.
enum PlayType {
  run,
  pass,
  touchdown,
  interception,
  fieldGoal,
  punt,
  kickoff,
  penalty,
  firstDown,
}

/// Um lance individual (play-by-play).
class Play {
  final String id;
  final String gameId;
  final String teamId;
  final String teamName;
  final String playerName;
  final String? receiverName;
  final String? playerPhotoUrl;
  final PlayType type;
  final String description;
  final int yards;
  final String quarter;
  final String time;
  final bool isFirstDown;
  final bool isTouchdown;
  final bool isTurnover;

  const Play({
    required this.id,
    required this.gameId,
    required this.teamId,
    required this.teamName,
    required this.playerName,
    this.receiverName,
    this.playerPhotoUrl,
    required this.type,
    required this.description,
    required this.yards,
    required this.quarter,
    required this.time,
    this.isFirstDown = false,
    this.isTouchdown = false,
    this.isTurnover = false,
  });
}

/// Mapeia o código snake_case do backend (ex.: FIELD_GOAL) para o nome
/// camelCase do enum [PlayType] do frontend (ex.: fieldGoal).
PlayType _mapPlayType(String backendCode) {
  const mapping = {
    'RUN': PlayType.run,
    'PASS': PlayType.pass,
    'TOUCHDOWN': PlayType.touchdown,
    'INTERCEPTION': PlayType.interception,
    'FIELD_GOAL': PlayType.fieldGoal,
    'PUNT': PlayType.punt,
    'KICKOFF': PlayType.kickoff,
    'PENALTY': PlayType.penalty,
    'FIRST_DOWN': PlayType.firstDown,
  };
  return mapping[backendCode.toUpperCase()] ?? PlayType.run;
}

/// Lances (play-by-play) reais de um jogo, consumindo
/// `GET /api/v1/games/{gameId}/plays`.
final playByPlayProvider =
    FutureProvider.family<List<Play>, String>((ref, gameId) async {
  final gameApi = ref.watch(gameApiProvider);
  final responses = await gameApi.findPlaysByGameId(gameId);
  return responses
      .map(
        (r) => Play(
          id: r.id,
          gameId: r.gameId,
          teamId: r.teamId,
          teamName: r.teamName,
          playerName: r.playerName,
          receiverName: r.receiverName,
          type: _mapPlayType(r.playType),
          description: r.description ?? '',
          yards: r.yards,
          quarter: r.quarter ?? 'Q1',
          time: r.time ?? '00:00',
          isFirstDown: r.isFirstDown,
          isTouchdown: r.isTouchdown,
          isTurnover: r.isTurnover,
        ),
      )
      .toList();
});

