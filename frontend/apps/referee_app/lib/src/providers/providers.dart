import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../router/app_router.dart';

final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(session: ref.watch(sessionManagerProvider)),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(
    session: ref.watch(sessionManagerProvider),
    api: ref.watch(authApiProvider),
  );
  controller.restore();
  return controller;
});

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);
  return AppRouter.build(auth);
});

final competitionApiProvider = Provider<CompetitionApi>(
  (ref) => CompetitionApi(ref.watch(apiClientProvider)),
);

/// Contexto de seleção compartilhado entre as telas de operação e check-in
/// (padrão admin_web), para não re-selecionar a cascata a cada visita.
final selectedCompetitionProvider = StateProvider<String?>((ref) => null);
final selectedRoundProvider = StateProvider<String?>((ref) => null);
final selectedGameProvider = StateProvider<String?>((ref) => null);

final competitionsProvider = FutureProvider<List<Competition>>(
  (ref) => ref.watch(competitionApiProvider).listAll(),
);

final roundApiProvider = Provider<RoundApi>(
  (ref) => RoundApi(ref.watch(apiClientProvider)),
);

/// Rodadas de um campeonato (fluxo único, sem categorias).
final roundsProvider = FutureProvider.family<List<Round>, String>(
  (ref, competitionId) =>
      ref.watch(roundApiProvider).listByCompetition(competitionId),
);

final gameApiProvider = Provider<GameApi>(
  (ref) => GameApi(ref.watch(apiClientProvider)),
);

final gamesByRoundProvider = FutureProvider.family<List<Game>, String>(
  (ref, roundId) => ref.watch(gameApiProvider).listByRound(roundId),
);

/// Eventos de pontuação (timeline) de um jogo.
final gameScoreEventsProvider = FutureProvider.family<List<ScoreEvent>, String>(
  (ref, gameId) => ref.watch(gameApiProvider).listScoreEvents(gameId),
);

final checkInApiProvider = Provider<CheckInApi>(
  (ref) => CheckInApi(ref.watch(apiClientProvider)),
);

final checkinProvider = FutureProvider.family<List<CheckIn>, String>(
  (ref, gameId) => ref.watch(checkInApiProvider).getList(gameId),
);
