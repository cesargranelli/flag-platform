import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../router/app_router.dart';

/// Gerenciador de sessão do Admin Web (persiste o token JWT).
final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(),
);

/// Cliente HTTP da API REST com o token da sessão injetado.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(session: ref.watch(sessionManagerProvider)),
);

/// Serviço de autenticação.
final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);

/// Controlador de autenticação (restaura a sessão ao iniciar).
final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(
    session: ref.watch(sessionManagerProvider),
    api: ref.watch(authApiProvider),
  );
  controller.restore();
  return controller;
});

/// Router com proteção de rotas.
///
/// Usa `ref.read` (e não `watch`) para manter a mesma instância do GoRouter
/// entre notificações; o redirect reage ao estado via `refreshListenable`.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);
  return AppRouter.build(auth);
});

/// Serviço de organizações.
final organizationApiProvider = Provider<OrganizationApi>(
  (ref) => OrganizationApi(ref.watch(apiClientProvider)),
);

/// Lista de organizações da tela de gestão.
final organizationsProvider = FutureProvider<List<Organization>>(
  (ref) => ref.watch(organizationApiProvider).list(),
);

/// Detalhe de uma organização por id.
final organizationProvider = FutureProvider.family<Organization, String>(
  (ref, id) => ref.watch(organizationApiProvider).getById(id),
);

/// Serviço de campeonatos.
final competitionApiProvider = Provider<CompetitionApi>(
  (ref) => CompetitionApi(ref.watch(apiClientProvider)),
);

/// Lista de campeonatos da tela de gestão.
final competitionsProvider = FutureProvider<List<Competition>>(
  (ref) => ref.watch(competitionApiProvider).listAll(),
);

/// Detalhe de um campeonato por id.
final competitionProvider = FutureProvider.family<Competition, String>(
  (ref, id) => ref.watch(competitionApiProvider).getById(id),
);

/// Serviço de categorias.
final categoryApiProvider = Provider<CategoryApi>(
  (ref) => CategoryApi(ref.watch(apiClientProvider)),
);

/// Campeonato selecionado na tela de categorias.
final selectedCompetitionProvider = StateProvider<String?>((ref) => null);

/// Categorias de um campeonato.
final categoriesProvider = FutureProvider.family<List<Category>, String>(
  (ref, competitionId) =>
      ref.watch(categoryApiProvider).listByCompetition(competitionId),
);

/// Detalhe de uma categoria por id.
final categoryProvider = FutureProvider.family<Category, String>(
  (ref, id) => ref.watch(categoryApiProvider).getById(id),
);

/// Serviço de campos de jogo.
final venueApiProvider = Provider<VenueApi>(
  (ref) => VenueApi(ref.watch(apiClientProvider)),
);

/// Lista de campos da tela de gestão.
final venuesProvider = FutureProvider<List<Venue>>(
  (ref) => ref.watch(venueApiProvider).list(),
);

/// Detalhe de um campo por id.
final venueProvider = FutureProvider.family<Venue, String>(
  (ref, id) => ref.watch(venueApiProvider).getById(id),
);

/// Serviço de times.
final teamApiProvider = Provider<TeamApi>(
  (ref) => TeamApi(ref.watch(apiClientProvider)),
);

/// Categoria selecionada na tela de times.
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Times de uma categoria.
final teamsProvider = FutureProvider.family<List<Team>, String>(
  (ref, categoryId) => ref.watch(teamApiProvider).listByCategory(categoryId),
);

/// Detalhe de um time por id.
final teamProvider = FutureProvider.family<Team, String>(
  (ref, id) => ref.watch(teamApiProvider).getById(id),
);

/// Serviço de rodadas.
final roundApiProvider = Provider<RoundApi>(
  (ref) => RoundApi(ref.watch(apiClientProvider)),
);

/// Rodadas de uma categoria.
final roundsProvider = FutureProvider.family<List<Round>, String>(
  (ref, categoryId) => ref.watch(roundApiProvider).listByCategory(categoryId),
);

/// Detalhe de uma rodada por id.
final roundProvider = FutureProvider.family<Round, String>(
  (ref, id) => ref.watch(roundApiProvider).getById(id),
);

/// Serviço de jogos.
final gameApiProvider = Provider<GameApi>(
  (ref) => GameApi(ref.watch(apiClientProvider)),
);

/// Rodada selecionada na tela de jogos.
final selectedRoundProvider = StateProvider<String?>((ref) => null);

/// Jogos de uma rodada.
final gamesByRoundProvider = FutureProvider.family<List<Game>, String>(
  (ref, roundId) => ref.watch(gameApiProvider).listByRound(roundId),
);

/// Detalhe de um jogo por id.
final gameProvider = FutureProvider.family<Game, String>(
  (ref, id) => ref.watch(gameApiProvider).getById(id),
);

/// Serviço de atletas.
final athleteApiProvider = Provider<AthleteApi>(
  (ref) => AthleteApi(ref.watch(apiClientProvider)),
);

/// Lista de atletas.
final athletesProvider = FutureProvider<List<Athlete>>(
  (ref) => ref.watch(athleteApiProvider).list(),
);

/// Detalhe de um atleta por id.
final athleteProvider = FutureProvider.family<Athlete, String>(
  (ref, id) => ref.watch(athleteApiProvider).getById(id),
);

/// Serviço de elencos.
final rosterApiProvider = Provider<RosterApi>(
  (ref) => RosterApi(ref.watch(apiClientProvider)),
);

/// Time selecionado na tela de elencos.
final selectedTeamProvider = StateProvider<String?>((ref) => null);

/// Elenco de um time.
final rosterProvider = FutureProvider.family<List<RosterEntry>, String>(
  (ref, teamId) => ref.watch(rosterApiProvider).listByTeam(teamId),
);

/// Lista de usuários (somente ADMIN).
final usersProvider = FutureProvider<List<User>>(
  (ref) => ref.watch(authApiProvider).listUsers(),
);

/// Contas pendentes de aprovação (somente ADMIN).
final pendingUsersProvider = FutureProvider<List<User>>(
  (ref) => ref.watch(authApiProvider).listPendingUsers(),
);
