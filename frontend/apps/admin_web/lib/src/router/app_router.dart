import 'package:flag_domain/flag_domain.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../screens/approvals_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/competitions_screen.dart';
import '../screens/groupings_screen.dart';
import '../screens/competition_create_screen.dart';
import '../screens/competition_edit_screen.dart';
import '../screens/competition_detail_screen.dart';
import '../screens/organization_detail_screen.dart';
import '../screens/organization_form_screen.dart';
import '../screens/organizations_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/venue_form_screen.dart';
import '../screens/venue_detail_screen.dart';
import '../screens/venues_screen.dart';
import '../screens/associate_clubs_screen.dart';
import '../screens/team_create_screen.dart';
import '../screens/team_edit_screen.dart';
import '../screens/team_detail_screen.dart';
import '../screens/teams_screen.dart';
import '../screens/round_form_screen.dart';
import '../screens/round_detail_screen.dart';
import '../screens/rounds_screen.dart';
import '../screens/game_form_screen.dart';
import '../screens/game_detail_screen.dart';
import '../screens/game_import_screen.dart';
import '../screens/games_screen.dart';
import '../screens/athlete_form_screen.dart';
import '../screens/athlete_import_screen.dart';
import '../screens/athlete_detail_screen.dart';
import '../screens/athletes_screen.dart';
import '../screens/rosters_screen.dart';
import '../screens/roster_import_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/user_form_screen.dart';
import '../screens/users_screen.dart';

/// Rotas do Admin Web com proteção de autenticação.
class AppRouter {
  /// Cria a configuração do GoRouter da aplicação.
  ///
  /// O [auth] é usado como `refreshListenable`: qualquer mudança de estado de
  /// autenticação reavalia o redirect (login/logout/proteção de rotas).
  static GoRouter build(AuthController auth) => GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final authenticated = auth.state.authenticated;
      final location = state.matchedLocation;
      final isPublicAuth =
          location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password' ||
          location == '/reset-password';

      // Não autenticado só acessa telas públicas de autenticação.
      if (!authenticated && !isPublicAuth) return '/login';
      // Autenticado não precisa ver telas de autenticação.
      if (authenticated && isPublicAuth) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'resetPassword',
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/organizations',
        name: 'organizations',
        builder: (context, state) => const OrganizationsScreen(),
      ),
      GoRoute(
        path: '/organizations/new',
        name: 'organizationNew',
        builder: (context, state) => const OrganizationFormScreen(),
      ),
      GoRoute(
        path: '/organizations/:id',
        name: 'organizationDetail',
        builder: (context, state) {
          final org = state.extra is Organization
              ? state.extra as Organization
              : null;
          return OrganizationDetailScreen(
            organizationId: state.pathParameters['id'],
            organization: org,
          );
        },
      ),
      GoRoute(
        path: '/competitions',
        name: 'competitions',
        builder: (context, state) => const CompetitionsScreen(),
      ),
      GoRoute(
        path: '/groupings',
        name: 'groupings',
        builder: (context, state) => const GroupingsScreen(),
      ),
      GoRoute(
        path: '/competitions/new',
        name: 'competitionNew',
        builder: (context, state) => const CompetitionCreateScreen(),
      ),
      GoRoute(
        path: '/competitions/:id',
        name: 'competitionDetail',
        builder: (context, state) {
          final competition = state.extra is Competition
              ? state.extra as Competition
              : null;
          return CompetitionDetailScreen(
            competitionId: state.pathParameters['id'],
            competition: competition,
          );
        },
      ),
      GoRoute(
        path: '/competitions/:id/edit',
        name: 'competitionEdit',
        builder: (context, state) {
          final competition = state.extra is Competition
              ? state.extra as Competition
              : null;
          return CompetitionEditScreen(
            competitionId: state.pathParameters['id'],
            competition: competition,
          );
        },
      ),
      GoRoute(
        path: '/venues',
        name: 'venues',
        builder: (context, state) => const VenuesScreen(),
      ),
      GoRoute(
        path: '/venues/new',
        name: 'venueNew',
        builder: (context, state) => const VenueFormScreen(),
      ),
      GoRoute(
        path: '/venues/:id',
        name: 'venueDetail',
        builder: (context, state) {
          final venue = state.extra is Venue ? state.extra as Venue : null;
          return VenueDetailScreen(
            venueId: state.pathParameters['id'],
            venue: venue,
          );
        },
      ),
      GoRoute(
        path: '/venues/:id/edit',
        name: 'venueEdit',
        builder: (context, state) {
          final venue = state.extra is Venue ? state.extra as Venue : null;
          return VenueFormScreen(
            venueId: state.pathParameters['id'],
            venue: venue,
          );
        },
      ),
      GoRoute(
        path: '/teams',
        name: 'teams',
        builder: (context, state) =>
            TeamsScreen(lockedCompetitionId: state.extra as String?),
      ),
      GoRoute(
        path: '/teams/associate',
        name: 'teamAssociate',
        builder: (context, state) =>
            AssociateClubsScreen(lockedCompetitionId: state.extra as String?),
      ),
      GoRoute(
        path: '/teams/new',
        name: 'teamNew',
        builder: (context, state) => const TeamCreateScreen(),
      ),
      GoRoute(
        path: '/teams/:id',
        name: 'teamDetail',
        builder: (context, state) {
          final team = state.extra is Team ? state.extra as Team : null;
          return TeamDetailScreen(
            teamId: state.pathParameters['id'],
            team: team,
          );
        },
      ),
      GoRoute(
        path: '/teams/:id/edit',
        name: 'teamEdit',
        builder: (context, state) {
          final team = state.extra is Team ? state.extra as Team : null;
          return TeamEditScreen(teamId: state.pathParameters['id'], team: team);
        },
      ),
      GoRoute(
        path: '/rounds',
        name: 'rounds',
        builder: (context, state) => const RoundsScreen(),
      ),
      GoRoute(
        path: '/rounds/new',
        name: 'roundNew',
        builder: (context, state) => RoundFormScreen(
          // competitionId removido do request direto; o service lida com o competition via division/competition lookup
        ),
      ),
      GoRoute(
        path: '/rounds/:id',
        name: 'roundDetail',
        builder: (context, state) {
          final round = state.extra is Round ? state.extra as Round : null;
          return RoundDetailScreen(
            roundId: state.pathParameters['id'],
            round: round,
          );
        },
      ),
      GoRoute(
        path: '/rounds/:id/edit',
        name: 'roundEdit',
        builder: (context, state) {
          final round = state.extra is Round ? state.extra as Round : null;
          return RoundFormScreen(
            roundId: state.pathParameters['id'],
            round: round,
          );
        },
      ),
      GoRoute(
        path: '/games',
        name: 'games',
        builder: (context, state) => const GamesScreen(),
      ),
      GoRoute(
        path: '/games/new',
        name: 'gameNew',
        builder: (context, state) => GameFormScreen(
          args: state.extra is GameFormArgs
              ? state.extra as GameFormArgs
              : null,
        ),
      ),
      GoRoute(
        path: '/games/import',
        name: 'gameImport',
        builder: (context, state) => GameImportScreen(
          roundId: state.extra is String ? state.extra as String : '',
        ),
      ),
      GoRoute(
        path: '/games/:id',
        name: 'gameDetail',
        builder: (context, state) => GameDetailScreen(
          gameId: state.pathParameters['id'],
          game: state.extra is Game ? state.extra as Game : null,
          args: null,
        ),
      ),
      GoRoute(
        path: '/games/:id/edit',
        name: 'gameEdit',
        builder: (context, state) => GameFormScreen(
          args: state.extra is GameFormArgs
              ? state.extra as GameFormArgs
              : null,
        ),
      ),
      GoRoute(
        path: '/athletes',
        name: 'athletes',
        builder: (context, state) => const AthletesScreen(),
      ),
      GoRoute(
        path: '/athletes/new',
        name: 'athleteNew',
        builder: (context, state) => const AthleteFormScreen(),
      ),
      GoRoute(
        path: '/athletes/import',
        name: 'athleteImport',
        builder: (context, state) => const AthleteImportScreen(),
      ),
      GoRoute(
        path: '/athletes/:id',
        name: 'athleteDetail',
        builder: (context, state) {
          final athlete = state.extra is Athlete
              ? state.extra as Athlete
              : null;
          return AthleteDetailScreen(
            athleteId: state.pathParameters['id'],
            athlete: athlete,
          );
        },
      ),
      GoRoute(
        path: '/athletes/:id/edit',
        name: 'athleteEdit',
        builder: (context, state) {
          final athlete = state.extra is Athlete
              ? state.extra as Athlete
              : null;
          return AthleteFormScreen(
            athleteId: state.pathParameters['id'],
            athlete: athlete,
          );
        },
      ),
      GoRoute(
        path: '/rosters',
        name: 'rosters',
        builder: (context, state) => const RostersScreen(),
      ),
      GoRoute(
        path: '/rosters/import',
        name: 'rosterImport',
        builder: (context, state) => RosterImportScreen(
          teamId: state.extra is String ? state.extra as String : '',
        ),
      ),
      GoRoute(
        path: '/users',
        name: 'users',
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: '/users/new',
        name: 'userNew',
        builder: (context, state) => const UserFormScreen(),
      ),
      GoRoute(
        path: '/approvals',
        name: 'approvals',
        builder: (context, state) => const ApprovalsScreen(),
      ),
    ],
  );
}
