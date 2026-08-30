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

/// Listagem para ADMIN: inclui desativadas quando [includeDisabled].
final organizationsAdminProvider =
    FutureProvider.family<List<Organization>, bool>(
  (ref, includeDisabled) => ref
      .watch(organizationApiProvider)
      .list(includeDisabled: includeDisabled),
);

/// Detalhe de uma organização por id.
final organizationProvider = FutureProvider.autoDispose.family<Organization, String>(
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

/// Listagem para ADMIN: inclui desativados quando [includeDisabled].
final competitionsAdminProvider =
    FutureProvider.family<List<Competition>, bool>(
  (ref, includeDisabled) => ref
      .watch(competitionApiProvider)
      .listAll(includeDisabled: includeDisabled),
);

/// Detalhe de um campeonato por id.
final competitionProvider = FutureProvider.autoDispose.family<Competition, String>(
  (ref, id) => ref.watch(competitionApiProvider).getById(id),
);

/// Campeonato selecionado na tela de competições.
final selectedCompetitionProvider = StateProvider<String?>((ref) => null);

/// Campeonato "efetivo" (P4 #461): o selecionado, ou o primeiro da lista
/// quando nada foi escolhido — padrão `selected ?? first` duplicado em
/// várias telas (games, rounds, teams, rosters, associate_clubs, game_form).
final effectiveCompetitionProvider = Provider<String?>((ref) {
  final selected = ref.watch(selectedCompetitionProvider);
  if (selected != null) return selected;
  final comps = ref.watch(competitionsProvider).valueOrNull ?? const [];
  return comps.isNotEmpty ? comps.first.id : null;
});

/// Serviço de times.
final teamApiProvider = Provider<TeamApi>(
  (ref) => TeamApi(ref.watch(apiClientProvider)),
);

/// Serviço de conferências.
final conferenceApiProvider = Provider<ConferenceApi>(
  (ref) => ConferenceApi(ref.watch(apiClientProvider)),
);

/// Serviço de divisões.
final divisionApiProvider = Provider<DivisionApi>(
  (ref) => DivisionApi(ref.watch(apiClientProvider)),
);

/// Conferências de um campeonato.
final conferencesProvider = FutureProvider.autoDispose.family<List<Conference>, String>(
  (ref, competitionId) =>
      ref.watch(conferenceApiProvider).listByCompetition(competitionId),
);

/// Divisões de um campeonato.
final divisionsProvider = FutureProvider.autoDispose.family<List<Division>, String>(
  (ref, competitionId) =>
      ref.watch(divisionApiProvider).listByCompetition(competitionId),
);

/// Times de um campeonato.
final teamsProvider = FutureProvider.autoDispose.family<List<Team>, String>(
  (ref, competitionId) =>
      ref.watch(teamApiProvider).listByCompetition(competitionId),
);

/// Detalhe de um time por id.
final teamProvider = FutureProvider.autoDispose.family<Team, String>(
  (ref, id) => ref.watch(teamApiProvider).getById(id),
);

/// Serviço de rodadas.
final roundApiProvider = Provider<RoundApi>(
  (ref) => RoundApi(ref.watch(apiClientProvider)),
);

/// Rodadas de um campeonato.
final roundsProvider = FutureProvider.autoDispose.family<List<Round>, String>(
  (ref, competitionId) =>
      ref.watch(roundApiProvider).listByCompetition(competitionId),
);

/// Detalhe de uma rodada por id.
final roundProvider = FutureProvider.autoDispose.family<Round, String>(
  (ref, id) => ref.watch(roundApiProvider).getById(id),
);

/// Serviço de jogos.
final gameApiProvider = Provider<GameApi>(
  (ref) => GameApi(ref.watch(apiClientProvider)),
);

/// Rodada selecionada na tela de jogos.
final selectedRoundProvider = StateProvider<String?>((ref) => null);

/// Jogos de uma rodada.
final gamesByRoundProvider = FutureProvider.autoDispose.family<List<Game>, String>(
  (ref, roundId) => ref.watch(gameApiProvider).listByRound(roundId),
);

/// Detalhe de um jogo por id.
final gameProvider = FutureProvider.autoDispose.family<Game, String>(
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
final athleteProvider = FutureProvider.autoDispose.family<Athlete, String>(
  (ref, id) => ref.watch(athleteApiProvider).getById(id),
);

/// Serviço de elencos.
final rosterApiProvider = Provider<RosterApi>(
  (ref) => RosterApi(ref.watch(apiClientProvider)),
);

/// Time selecionado na tela de elencos.
final selectedTeamProvider = StateProvider<String?>((ref) => null);

/// Elenco de um time.
final rosterProvider = FutureProvider.autoDispose.family<List<RosterEntry>, String>(
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

/// Serviço de campos de jogo.
final venueApiProvider = Provider<VenueApi>(
  (ref) => VenueApi(ref.watch(apiClientProvider)),
);

/// Lista de campos de jogo.
final venuesProvider = FutureProvider<List<Venue>>(
  (ref) => ref.watch(venueApiProvider).list(),
);

/// Detalhe de um campo por id.
final venueProvider = FutureProvider.autoDispose.family<Venue, String>(
  (ref, id) => ref.watch(venueApiProvider).getById(id),
);
