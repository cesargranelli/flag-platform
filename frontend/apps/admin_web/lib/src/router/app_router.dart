import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
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
import '../screens/team_roster_screen.dart';
import '../screens/roster_import_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/user_form_screen.dart';
import '../screens/users_screen.dart';
import '../screens/visual_test_screen.dart';
import '../widgets/admin_shell.dart';

/// Rotas do Admin Web com proteção de autenticação.
///
/// A navegação autenticada vive dentro de uma
/// [StatefulShellRoute.indexedStack] com uma branch por módulo (issue #427):
/// o [AdminShell] exibe header global + breadcrumb, e cada branch preserva
/// seu estado (filtros/seletores). Telas de autenticação ficam FORA da shell.
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
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 56, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              'Página não encontrada',
              style: AppTextStyles.headline1.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              'O link que você acessou não existe.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.go('/'),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // ---------------------------------------------------------------- //
      // Telas públicas de autenticação (fora da shell).
      // ---------------------------------------------------------------- //
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
      // ---------------------------------------------------------------- //
      // Shell do site (header global + breadcrumb) com branches por módulo.
      // A ordem das branches espelha AdminShell._destinations.
      // ---------------------------------------------------------------- //
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdminShell(
          navigationShell: navigationShell,
          location: state.uri.path,
          extra: state.extra,
        ),
        branches: [
          // Branch Início.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const AdminHomeScreen(),
              ),
            ],
          ),
          // Branch Organizações.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/organizations',
                name: 'organizations',
                builder: (context, state) => const OrganizationsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'organizationNew',
                    builder: (context, state) =>
                        const OrganizationFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
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
                ],
              ),
            ],
          ),
          // Branch Campeonatos (inclui conferências/divisões, rodadas e
          // jogos — acessados por contexto de campeonato).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/competitions',
                name: 'competitions',
                builder: (context, state) => const CompetitionsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'competitionNew',
                    builder: (context, state) =>
                        const CompetitionCreateScreen(),
                  ),
                  GoRoute(
                    path: ':id',
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
                    routes: [
                      GoRoute(
                        path: 'edit',
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
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/groupings',
                name: 'groupings',
                builder: (context, state) => const GroupingsScreen(),
              ),
              GoRoute(
                path: '/rounds',
                name: 'rounds',
                builder: (context, state) => const RoundsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'roundNew',
                    builder: (context, state) => RoundFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'roundDetail',
                    builder: (context, state) {
                      final round = state.extra is Round
                          ? state.extra as Round
                          : null;
                      return RoundDetailScreen(
                        roundId: state.pathParameters['id'],
                        round: round,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: 'roundEdit',
                        builder: (context, state) {
                          final round = state.extra is Round
                              ? state.extra as Round
                              : null;
                          return RoundFormScreen(
                            roundId: state.pathParameters['id'],
                            round: round,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/games',
                name: 'games',
                builder: (context, state) => const GamesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'gameNew',
                    builder: (context, state) => GameFormScreen(
                      args: state.extra is GameFormArgs
                          ? state.extra as GameFormArgs
                          : null,
                    ),
                  ),
                  GoRoute(
                    path: 'import',
                    name: 'gameImport',
                    builder: (context, state) => GameImportScreen(
                      roundId: state.extra is String ? state.extra as String : '',
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'gameDetail',
                    builder: (context, state) => GameDetailScreen(
                      gameId: state.pathParameters['id'],
                      game: state.extra is Game ? state.extra as Game : null,
                      args: null,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: 'gameEdit',
                        builder: (context, state) => GameFormScreen(
                          args: state.extra is GameFormArgs
                              ? state.extra as GameFormArgs
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch Campos (venues).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/venues',
                name: 'venues',
                builder: (context, state) => const VenuesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'venueNew',
                    builder: (context, state) => const VenueFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'venueDetail',
                    builder: (context, state) {
                      final venue = state.extra is Venue
                          ? state.extra as Venue
                          : null;
                      return VenueDetailScreen(
                        venueId: state.pathParameters['id'],
                        venue: venue,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: 'venueEdit',
                        builder: (context, state) {
                          final venue = state.extra is Venue
                              ? state.extra as Venue
                              : null;
                          return VenueFormScreen(
                            venueId: state.pathParameters['id'],
                            venue: venue,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch Times.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teams',
                name: 'teams',
                builder: (context, state) => TeamsScreen(
                  lockedCompetitionId: state.extra as String?,
                ),
                routes: [
                  GoRoute(
                    path: 'associate',
                    name: 'teamAssociate',
                    builder: (context, state) => AssociateClubsScreen(
                      lockedCompetitionId: state.extra as String?,
                    ),
                  ),
                  GoRoute(
                    path: 'new',
                    name: 'teamNew',
                    builder: (context, state) => const TeamCreateScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'teamDetail',
                    builder: (context, state) {
                      final team = state.extra is Team
                          ? state.extra as Team
                          : null;
                      return TeamDetailScreen(
                        teamId: state.pathParameters['id'],
                        team: team,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: 'teamEdit',
                        builder: (context, state) {
                          final team = state.extra is Team
                              ? state.extra as Team
                              : null;
                          return TeamEditScreen(
                            teamId: state.pathParameters['id'],
                            team: team,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'roster',
                        name: 'teamRoster',
                        builder: (context, state) {
                          final team = state.extra is Team
                              ? state.extra as Team
                              : null;
                          return TeamRosterScreen(
                            team: team,
                            teamId: state.pathParameters['id'],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch Atletas.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/athletes',
                name: 'athletes',
                builder: (context, state) => const AthletesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'athleteNew',
                    builder: (context, state) => const AthleteFormScreen(),
                  ),
                  GoRoute(
                    path: 'import',
                    name: 'athleteImport',
                    builder: (context, state) => const AthleteImportScreen(),
                  ),
                  GoRoute(
                    path: ':id',
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
                    routes: [
                      GoRoute(
                        path: 'edit',
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
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branch Elencos.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rosters',
                name: 'rosters',
                builder: (context, state) => const RostersScreen(),
                routes: [
                  GoRoute(
                    path: 'import',
                    name: 'rosterImport',
                    builder: (context, state) => RosterImportScreen(
                      teamId: state.extra is String ? state.extra as String : '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch Aprovações (somente ADMIN — protegida no backend).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/approvals',
                name: 'approvals',
                builder: (context, state) => const ApprovalsScreen(),
              ),
            ],
          ),
          // Branch Usuários (somente ADMIN).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/users',
                name: 'users',
                builder: (context, state) => const UsersScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'userNew',
                    builder: (context, state) => const UserFormScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch Teste visual (somente ADMIN).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/visual-test',
                name: 'visualTest',
                builder: (context, state) => const VisualTestScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}