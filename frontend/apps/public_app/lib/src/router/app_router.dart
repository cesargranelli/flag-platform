import 'package:go_router/go_router.dart';

import '../screens/competition_detail_screen.dart';
import '../screens/competition_games_screen.dart';
import '../screens/competition_results_screen.dart';
import '../screens/competition_standings_screen.dart';
import '../screens/game_detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/team_detail_screen.dart';

/// Rotas do Public App.
class AppRouter {
  /// Cria a configuração do GoRouter da aplicação.
  ///
  /// Constrói uma instância nova a cada chamada para não compartilhar estado
  /// de navegação entre builds/testes.
  static GoRouter build() => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/competition/:id',
        name: 'competitionDetail',
        builder: (context, state) => CompetitionDetailScreen(
          // O nome é passado via `extra` no `context.push`; em deep links
          // (sem extra) a tela usa o id como fallback.
          competitionId: state.pathParameters['id']!,
          competitionName: state.extra as String? ?? '',
        ),
        routes: [
          GoRoute(
            path: 'games',
            name: 'competitionGames',
            builder: (context, state) => CompetitionGamesScreen(
              competitionId: state.pathParameters['id']!,
              competitionName: state.extra as String? ?? '',
            ),
          ),
          GoRoute(
            path: 'results',
            name: 'competitionResults',
            builder: (context, state) => CompetitionResultsScreen(
              competitionId: state.pathParameters['id']!,
              competitionName: state.extra as String? ?? '',
            ),
          ),
          GoRoute(
            path: 'standings',
            name: 'competitionStandings',
            builder: (context, state) => CompetitionStandingsScreen(
              competitionId: state.pathParameters['id']!,
              competitionName: state.extra as String? ?? '',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/game/:id',
        name: 'gameDetail',
        builder: (context, state) {
          // O jogo completo e o nome do campeonato podem vir via `extra`
          // (GameDetailArgs) para exibição imediata; em deep links a tela
          // busca o jogo por id.
          final args = state.extra is GameDetailArgs
              ? state.extra as GameDetailArgs
              : null;
          return GameDetailScreen(
            gameId: args?.gameId ?? state.pathParameters['id']!,
            game: args?.game,
            competitionName: args?.competitionName ?? '',
          );
        },
      ),
      GoRoute(
        path: '/teams/:id',
        name: 'teamDetail',
        builder: (context, state) {
          // O nome do time pode vir via `extra` (TeamDetailArgs) para
          // exibição imediata; em deep links a tela busca o time por id.
          final args = state.extra is TeamDetailArgs
              ? state.extra as TeamDetailArgs
              : null;
          return TeamDetailScreen(
            teamId: args?.teamId ?? state.pathParameters['id']!,
            teamName: args?.teamName ?? '',
          );
        },
      ),
    ],
  );
}
