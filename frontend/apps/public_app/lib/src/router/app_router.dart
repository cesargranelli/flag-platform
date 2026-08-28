import 'package:go_router/go_router.dart';

import '../screens/about_screen.dart';
import '../screens/competition_detail_screen.dart';
import '../screens/game_detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/live_screen.dart';
import '../screens/team_detail_screen.dart';
import '../widgets/public_shell.dart';

/// Rotas do Public App (issue #389).
///
/// A navegação principal (Início · Campeonato · Ao vivo · Sobre) vive dentro de
/// uma [StatefulShellRoute]: cada aba preserva seu próprio estado e back stack.
/// Telas de detalhe de jogo/time (`/game/:id`, `/teams/:id`) ficam FORA da
/// shell — são empilhadas sobre a barra inferior (padrão de apps).
class AppRouter {
  /// Cria a configuração do GoRouter da aplicação.
  ///
  /// Constrói uma instância nova a cada chamada para não compartilhar estado
  /// de navegação entre builds/testes.
  static GoRouter build() => GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            PublicShell(navigationShell: navigationShell),
        branches: [
          // Aba Início: lista de campeonatos.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Aba Campeonato: hub do campeonato em foco (ou orientador vazio).
          StatefulShellBranch(
            routes: [
              // Rota sem id: usada quando não há campeonato em foco — o hub
              // exibe o orientador "Escolha um campeonato" (#389).
              GoRoute(
                path: '/competition',
                name: 'competitionHub',
                builder: (context, state) => const CompetitionDetailScreen(),
              ),
              GoRoute(
                path: '/competition/:id',
                name: 'competitionDetail',
                // O nome pode vir via `extra`; em deep links a tela usa o
                // campeonato em foco como fallback (e define o foco).
                builder: (context, state) => CompetitionDetailScreen(
                  competitionId: state.pathParameters['id']!,
                  competitionName: state.extra as String?,
                ),
                routes: [
                  GoRoute(
                    path: 'games',
                    name: 'competitionGames',
                    builder: (context, state) => CompetitionDetailScreen(
                      competitionId: state.pathParameters['id']!,
                      competitionName: state.extra as String?,
                      initialTab: 0,
                    ),
                  ),
                  GoRoute(
                    path: 'results',
                    name: 'competitionResults',
                    builder: (context, state) => CompetitionDetailScreen(
                      competitionId: state.pathParameters['id']!,
                      competitionName: state.extra as String?,
                      initialTab: 1,
                    ),
                  ),
                  GoRoute(
                    path: 'standings',
                    name: 'competitionStandings',
                    builder: (context, state) => CompetitionDetailScreen(
                      competitionId: state.pathParameters['id']!,
                      competitionName: state.extra as String?,
                      initialTab: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Aba Ao vivo: timeline de livescore (dados fake, #391).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/live',
                name: 'live',
                builder: (context, state) => const LiveScreen(),
              ),
            ],
          ),
          // Aba Sobre.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/about',
                name: 'about',
                builder: (context, state) => const AboutScreen(),
              ),
            ],
          ),
        ],
      ),
      // Detalhes empilhados sobre a shell (sem a barra inferior).
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
