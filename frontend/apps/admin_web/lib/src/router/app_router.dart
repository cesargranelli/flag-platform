import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

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
          final onLogin = state.matchedLocation == '/login';

          // Não autenticado só acessa a tela de login.
          if (!authenticated && !onLogin) return '/login';
          // Autenticado não precisa ver o login novamente.
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
            builder: (context, state) => const AdminHomeScreen(),
          ),
        ],
      );
}
