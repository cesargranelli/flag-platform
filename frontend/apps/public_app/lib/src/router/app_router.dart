import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/about_screen.dart';
import '../screens/competition_detail_screen.dart';
import '../screens/game_detail_screen.dart';
import '../screens/live_screen.dart';
import '../screens/play_by_play_screen.dart';
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
    initialLocation: '/live',
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
              onPressed: () => context.go('/live'),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            PublicShell(navigationShell: navigationShell),
        branches: [
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
          // Aba Campeonato: hub do campeonato em foco (ou lista quando vazio).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/competition',
                name: 'competitionHub',
                builder: (context, state) => const CompetitionDetailScreen(),
              ),
              GoRoute(
                path: '/competition/:id',
                name: 'competitionDetail',
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
      GoRoute(
        path: '/live/:id/plays',
        name: 'playByPlay',
        builder: (context, state) {
          final args = state.extra as Game?;
          return PlayByPlayScreen(
            gameId: state.pathParameters['id']!,
            game: args,
          );
        },
      ),
    ],
  );
}
