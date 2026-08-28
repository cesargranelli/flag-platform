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

/// Dados FAKE de livescore (issue #391) — demonstração do "Ao vivo" no próprio
/// app, sem backend. Só um Provider que gera jogos ao vivo/encerrados com
/// datas relativas ao momento da leitura e metadados de filtro.
final fakeLiveGamesProvider = Provider<List<LiveGame>>((ref) {
  final now = DateTime.now();

  LiveGame live(
    String id,
    String home,
    String away,
    int homeScore,
    int awayScore,
    String venue,
    int round,
    Duration ago, {
    required String competition,
    required Modality modality,
    required Gender gender,
  }) {
    return LiveGame(
      game: Game(
        id: id,
        roundId: 'round-$round',
        competitionId: 'fake-${competition.hashCode}',
        roundNumber: round,
        homeTeamId: 'team-$id-h',
        awayTeamId: 'team-$id-a',
        homeTeamName: home,
        awayTeamName: away,
        venueId: 'venue-$id',
        venueName: venue,
        scheduledAt: now.subtract(ago),
        status: GameStatus.inProgress,
        homeScore: homeScore,
        awayScore: awayScore,
      ),
      competitionName: competition,
      modality: modality,
      gender: gender,
    );
  }

  LiveGame finished(
    String id,
    String home,
    String away,
    int homeScore,
    int awayScore,
    String venue,
    int round,
    Duration ago, {
    required String competition,
    required Modality modality,
    required Gender gender,
  }) {
    return LiveGame(
      game: Game(
        id: id,
        roundId: 'round-$round',
        competitionId: 'fake-${competition.hashCode}',
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
      ),
      competitionName: competition,
      modality: modality,
      gender: gender,
    );
  }

  return [
    live('live-1', 'Tigers', 'Lynx', 14, 8, 'Campo Central', 1, const Duration(minutes: 35),
        competition: 'Copa Brasil', modality: Modality.flag5x5, gender: Gender.male),
    live('live-2', 'Eagles', 'Hawks', 0, 6, 'Campo Norte', 1, const Duration(minutes: 12),
        competition: 'Copa Brasil', modality: Modality.flag8x8, gender: Gender.male),
    live('live-3', 'Wolves', 'Bears', 21, 14, 'Campo Sul', 2, const Duration(minutes: 55),
        competition: 'Liga Regional', modality: Modality.flag5x5, gender: Gender.female),
    live('live-4', 'Falcons', 'Panthers', 7, 7, 'Campo Leste', 2, const Duration(hours: 1, minutes: 18),
        competition: 'Liga Regional', modality: Modality.flag9x9, gender: Gender.female),
    finished('done-1', 'Sharks', 'Dolphins', 21, 0, 'Campo Central', 3, const Duration(hours: 2),
        competition: 'Copa Brasil', modality: Modality.flag5x5, gender: Gender.mixed),
    finished('done-2', 'Lions', 'Tigers', 12, 22, 'Campo Norte', 3, const Duration(hours: 2, minutes: 40),
        competition: 'Copa Brasil', modality: Modality.flag9x9, gender: Gender.male),
  ];
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

/// Dados FAKE de lances (play-by-play) para demonstração.
final fakePlayByPlayProvider =
    FutureProvider.family<List<Play>, String>((ref, gameId) async {
  // Simula latency de rede
  await Future.delayed(const Duration(milliseconds: 300));

  // Liga de exemplo: time A = laranja, time B = azul
  final isGame1 = gameId == 'live-1';
  final homeTeam = isGame1 ? 'Clube 01' : 'Clube 05';
  final awayTeam = isGame1 ? 'Clube 02' : 'Clube 06';

  return [
    Play(
      id: 'play-1',
      gameId: gameId,
      teamId: 'team-a',
      teamName: homeTeam,
      playerName: 'Carlos Silva',
      receiverName: 'Pedro Costa',
      type: PlayType.pass,
      description: 'Carlos Silva → Pedro Costa | 12 jds',
      yards: 12,
      quarter: 'Q2',
      time: '08:32',
      isFirstDown: true,
    ),
    Play(
      id: 'play-2',
      gameId: gameId,
      teamId: 'team-a',
      teamName: homeTeam,
      playerName: 'Pedro Costa',
      type: PlayType.run,
      description: 'Pedro Costa | 5 jds',
      yards: 5,
      quarter: 'Q2',
      time: '08:15',
    ),
    Play(
      id: 'play-3',
      gameId: gameId,
      teamId: 'team-a',
      teamName: homeTeam,
      playerName: 'Lucas Ferreira',
      receiverName: 'Gabriel Oliveira',
      type: PlayType.pass,
      description: 'Lucas Ferreira → Gabriel Oliveira | 8 jds',
      yards: 8,
      quarter: 'Q2',
      time: '07:58',
    ),
    Play(
      id: 'play-4',
      gameId: gameId,
      teamId: 'team-b',
      teamName: awayTeam,
      playerName: 'André Mendes',
      type: PlayType.interception,
      description: 'André Mendes | Interceptação!',
      yards: 0,
      quarter: 'Q2',
      time: '07:45',
      isTurnover: true,
    ),
    Play(
      id: 'play-5',
      gameId: gameId,
      teamId: 'team-b',
      teamName: awayTeam,
      playerName: 'Rafael Santos',
      type: PlayType.run,
      description: 'Rafael Santos | 3 jds',
      yards: 3,
      quarter: 'Q2',
      time: '07:30',
    ),
    Play(
      id: 'play-6',
      gameId: gameId,
      teamId: 'team-a',
      teamName: homeTeam,
      playerName: 'Gabriel Oliveira',
      receiverName: 'Lucas Ferreira',
      type: PlayType.touchdown,
      description: 'Gabriel Oliveira → Lucas Ferreira | 25 jds — TOUCHDOWN!',
      yards: 25,
      quarter: 'Q2',
      time: '07:12',
      isTouchdown: true,
    ),
  ];
});

