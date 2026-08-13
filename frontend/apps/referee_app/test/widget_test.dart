import 'package:flag_api/flag_api.dart';
import 'package:flag_referee_app/src/app.dart';
import 'package:flag_referee_app/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required InMemorySessionManager session,
    required FakeAuthApi api,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(api),
        ],
        child: const FlagRefereeApp(),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('sem sessão, redireciona para a tela de login',
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        session: InMemorySessionManager(),
        api: FakeAuthApi(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flag Referee App'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('login com sucesso autentica e navega para a home',
        (WidgetTester tester) async {
      final session = InMemorySessionManager();
      final api = FakeAuthApi()..loginResponse = testLoginResponse();

      await pumpApp(tester, session: session, api: api);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).at(0), 'mesa@exemplo.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'segredo123');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo, Mesa Central!'), findsOneWidget);
      expect(await session.getToken(), 'jwt-token-de-teste');
    });

    testWidgets('login com credenciais inválidas mostra mensagem de erro',
        (WidgetTester tester) async {
      final api = FakeAuthApi()
        ..failure = const RepositoryException(
          'E-mail ou senha inválidos.',
          statusCode: 401,
        );

      await pumpApp(
        tester,
        session: InMemorySessionManager(),
        api: api,
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).at(0), 'mesa@exemplo.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'errada');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
    });
  });

  group('Proteção de rotas', () {
    testWidgets('com sessão restaurada, inicia na home',
        (WidgetTester tester) async {
      final session = InMemorySessionManager()
        ..seedToken('jwt', roles: ['MESA'], userName: 'Mesa Central');
      final api = FakeAuthApi()..meUser = testUser();

      await pumpApp(tester, session: session, api: api);
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo, Mesa Central!'), findsOneWidget);
      expect(find.text('Entrar'), findsNothing);
    });

    testWidgets('logout limpa a sessão e volta para o login',
        (WidgetTester tester) async {
      final session = InMemorySessionManager();
      final api = FakeAuthApi()..loginResponse = testLoginResponse();

      await pumpApp(tester, session: session, api: api);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).at(0), 'mesa@exemplo.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'segredo123');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.text('Entrar'), findsOneWidget);
      expect(await session.getToken(), isNull);
    });
  });
}
