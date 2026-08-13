import 'package:flag_domain/flag_domain.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../screens/categories_screen.dart';
import '../screens/category_form_screen.dart';
import '../screens/competition_form_screen.dart';
import '../screens/competitions_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/organization_form_screen.dart';
import '../screens/organizations_screen.dart';

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
            name: 'organizationEdit',
            builder: (context, state) {
              final org = state.extra is Organization
                  ? state.extra as Organization
                  : null;
              return OrganizationFormScreen(
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
            path: '/competitions/new',
            name: 'competitionNew',
            builder: (context, state) => const CompetitionFormScreen(),
          ),
          GoRoute(
            path: '/competitions/:id',
            name: 'competitionEdit',
            builder: (context, state) {
              final competition = state.extra is Competition
                  ? state.extra as Competition
                  : null;
              return CompetitionFormScreen(
                competitionId: state.pathParameters['id'],
                competition: competition,
              );
            },
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/categories/new',
            name: 'categoryNew',
            builder: (context, state) => const CategoryFormScreen(),
          ),
          GoRoute(
            path: '/categories/:id',
            name: 'categoryEdit',
            builder: (context, state) {
              final category = state.extra is Category
                  ? state.extra as Category
                  : null;
              return CategoryFormScreen(
                categoryId: state.pathParameters['id'],
                category: category,
              );
            },
          ),
        ],
      );
}
