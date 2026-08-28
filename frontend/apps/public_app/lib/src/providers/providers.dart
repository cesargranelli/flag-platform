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

/// Dados FAKE de livescore (issue #391) — demonstração do "Ao vivo" no próprio
/// app, sem backend. Só um Provider que gera jogos ao vivo/encerrados com
/// datas relativas ao momento da leitura.
final fakeLiveGamesProvider = Provider<List<Game>>((ref) {
  final now = DateTime.now();

  Game live(
    String id,
    String home,
    String away,
    int homeScore,
    int awayScore,
    String venue,
    int round,
    Duration ago,
  ) {
    return Game(
      id: id,
      roundId: 'round-$round',
      competitionId: 'fake',
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
    );
  }

  Game finished(
    String id,
    String home,
    String away,
    int homeScore,
    int awayScore,
    String venue,
    int round,
    Duration ago,
  ) {
    return Game(
      id: id,
      roundId: 'round-$round',
      competitionId: 'fake',
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
    live('live-1', 'Clube 01', 'Clube 02', 14, 8, 'Campo 01', 1, const Duration(minutes: 35)),
    live('live-2', 'Clube 03', 'Clube 04', 0, 6, 'Campo 02', 1, const Duration(minutes: 12)),
    live('live-3', 'Clube 05', 'Clube 06', 21, 14, 'Campo 01', 2, const Duration(minutes: 55)),
    live('live-4', 'Clube 07', 'Clube 08', 7, 7, 'Campo 02', 2, const Duration(hours: 1, minutes: 18)),
    finished('done-1', 'Clube 09', 'Clube 10', 21, 0, 'Campo 01', 3, const Duration(hours: 2)),
    finished('done-2', 'Clube 11', 'Clube 12', 12, 22, 'Campo 02', 3, const Duration(hours: 2, minutes: 40)),
  ];
});

