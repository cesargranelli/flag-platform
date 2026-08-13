import 'package:go_router/go_router.dart';

import '../screens/competition_detail_screen.dart';
import '../screens/home_screen.dart';

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
      ),
    ],
  );
}
