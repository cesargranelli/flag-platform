import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../screens/check_in_screen.dart';
import '../screens/game_operation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

/// Rotas do Referee App com proteção de autenticação.
class AppRouter {
  /// Cria a configuração do GoRouter da aplicação.
  ///
  /// O [auth] é usado como `refreshListenable`: qualquer mudança de estado de
  /// autenticação reavalia o redirect (login/logout/proteção de rotas).
  static GoRouter build(AuthController auth) {
    // Destino original antes do redirect para o login (issue #425#33):
    // após autenticar, o usuário volta para onde tentava ir.
    String? pendingDestination;

    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final authState = auth.state;

        // Restaurando a sessão: mantém a tela de boot até decidir (#27).
        if (authState.restoring) return '/boot';

        final authenticated = authState.authenticated;
        final location = state.matchedLocation;
        final isAuthScreen = location == '/login';
        final isBoot = location == '/boot';

        // Não autenticado: guarda o destino e vai para o login (#33).
        if (!authenticated) {
          if (!isAuthScreen && !isBoot) pendingDestination = location;
          return isAuthScreen ? null : '/login';
        }

        // Autenticado: sai das telas de autenticação e segue ao destino.
        if (isAuthScreen || isBoot) {
          final destination = pendingDestination;
          pendingDestination = null;
          return destination ?? '/';
        }
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
        GoRoute(
          path: '/boot',
          name: 'boot',
          builder: (context, state) => const _BootScreen(),
        ),
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
        GoRoute(
          path: '/checkin',
          name: 'checkin',
          builder: (context, state) => const CheckInScreen(),
        ),
      ],
    );
  }
}

/// Tela de boot exibida enquanto a sessão é restaurada (issue #425#27).
class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppLoading(message: 'Restaurando sessão...'),
    );
  }
}