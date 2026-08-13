import 'package:flag_api/flag_api.dart';
import 'package:flag_admin_web/src/auth/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  group('AuthController', () {
    test('restore mantém deslogado quando não há token', () async {
      final session = InMemorySessionManager();
      final controller = AuthController(session: session, api: FakeAuthApi());

      await controller.restore();

      expect(controller.state.authenticated, isFalse);
      expect(controller.state.user, isNull);
    });

    test('restore autentica quando há token válido', () async {
      final session = InMemorySessionManager()
        ..seedToken('jwt', userName: 'Ana Lima');
      final api = FakeAuthApi()..meUser = testUser();
      final controller = AuthController(session: session, api: api);

      await controller.restore();

      expect(controller.state.authenticated, isTrue);
      expect(controller.state.user?.email, 'ana@exemplo.com');
    });

    test('login autentica e persiste o token e roles', () async {
      final session = InMemorySessionManager();
      final api = FakeAuthApi()..loginResponse = testLoginResponse();
      final controller = AuthController(session: session, api: api);

      await controller.login(email: 'ana@exemplo.com', password: 'segredo123');

      expect(controller.state.authenticated, isTrue);
      expect(controller.state.user?.name, 'Ana Lima');
      expect(await session.getToken(), 'jwt-token-de-teste');
      expect(await session.getRoles(), ['ORGANIZER']);
    });

    test('login propaga erro de credenciais inválidas', () async {
      final session = InMemorySessionManager();
      final api = FakeAuthApi()
        ..failure = const RepositoryException(
          'E-mail ou senha inválidos.',
          statusCode: 401,
        );
      final controller = AuthController(session: session, api: api);

      await expectLater(
        controller.login(email: 'ana@exemplo.com', password: 'errada'),
        throwsA(isA<RepositoryException>()),
      );

      expect(controller.state.authenticated, isFalse);
      expect(await session.getToken(), isNull);
    });

    test('logout limpa a sessão e desautentica', () async {
      final session = InMemorySessionManager()
        ..seedToken('jwt', roles: ['ORGANIZER'], userName: 'Ana Lima');
      final api = FakeAuthApi()..meUser = testUser();
      final controller = AuthController(session: session, api: api);
      await controller.restore();

      await controller.logout();

      expect(controller.state.authenticated, isFalse);
      expect(await session.getToken(), isNull);
    });
  });
}
