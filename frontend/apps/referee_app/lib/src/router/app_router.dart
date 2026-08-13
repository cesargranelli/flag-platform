import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../screens/game_operation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

/// Rotas do Referee App com proteção de autenticação.
class AppRouter {
  static GoRouter build(AuthController auth) => GoRouter(
        initialLocation: '/',
        refreshListenable: auth,
        redirect: (context, state) {
          final authenticated = auth.state.authenticated;
          final onLogin = state.matchedLocation == '/login';

          if (!authenticated && !onLogin) return '/login';
          if (authenticated && onLogin) return '/';

          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const RefereeHomeScreen(),
          ),
          GoRoute(
            path: '/operation',
            name: 'operation',
            builder: (context, state) => const GameOperationScreen(),
          ),
        ],
      );
}
