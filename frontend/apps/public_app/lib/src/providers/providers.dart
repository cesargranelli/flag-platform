import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Serviço de categorias.
final categoryApiProvider = Provider<CategoryApi>(
  (ref) => CategoryApi(ref.watch(apiClientProvider)),
);

/// Categorias de uma competição, ordenadas por nome.
final competitionCategoriesProvider = FutureProvider.family<List<Category>, String>(
  (ref, competitionId) =>
      ref.watch(categoryApiProvider).listByCompetition(competitionId),
);

/// Serviço de classificação.
final standingApiProvider = Provider<StandingApi>(
  (ref) => StandingApi(ref.watch(apiClientProvider)),
);

/// Tabela de classificação de uma categoria.
final categoryStandingsProvider = FutureProvider.family<List<Standing>, String>(
  (ref, categoryId) =>
      ref.watch(standingApiProvider).listByCategory(categoryId),
);
