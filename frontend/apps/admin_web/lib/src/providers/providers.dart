import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../router/app_router.dart';

/// Gerenciador de sessão do Admin Web (persiste o token JWT).
final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(),
);

/// Cliente HTTP da API REST com o token da sessão injetado.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(session: ref.watch(sessionManagerProvider)),
);

/// Serviço de autenticação.
final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);

/// Controlador de autenticação (restaura a sessão ao iniciar).
final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(
    session: ref.watch(sessionManagerProvider),
    api: ref.watch(authApiProvider),
  );
  controller.restore();
  return controller;
});

/// Router com proteção de rotas.
///
/// Usa `ref.read` (e não `watch`) para manter a mesma instância do GoRouter
/// entre notificações; o redirect reage ao estado via `refreshListenable`.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);
  return AppRouter.build(auth);
});

/// Serviço de organizações.
final organizationApiProvider = Provider<OrganizationApi>(
  (ref) => OrganizationApi(ref.watch(apiClientProvider)),
);

/// Lista de organizações da tela de gestão.
final organizationsProvider = FutureProvider<List<Organization>>(
  (ref) => ref.watch(organizationApiProvider).list(),
);

/// Detalhe de uma organização por id.
final organizationProvider = FutureProvider.family<Organization, String>(
  (ref, id) => ref.watch(organizationApiProvider).getById(id),
);
