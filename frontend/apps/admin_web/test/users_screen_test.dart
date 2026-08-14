import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required FakeAuthApi authApi,
    String userRole = 'ADMIN',
  }) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: [userRole], userName: 'Admin');
    final meUser = User(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Admin',
      email: 'admin@exemplo.com',
      role: userRole,
    );
    authApi.meUser = meUser;

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  Future<void> openUsers(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Usuários'), 120);
    await tester.ensureVisible(find.text('Usuários'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuários'));
    await tester.pumpAndSettle();
  }

  testWidgets('admin vê o menu e lista os usuários', (WidgetTester tester) async {
    final api = FakeAuthApi()
      ..users = [
        User(id: '1', name: 'Ana Lima', email: 'ana@exemplo.com', role: 'ORGANIZER'),
        User(id: '2', name: 'Mesa Central', email: 'mesa@exemplo.com', role: 'MESA'),
      ];

    await pumpApp(tester, authApi: api);
    await tester.pumpAndSettle();
    await openUsers(tester);

    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Mesa Central'), findsOneWidget);
    expect(find.textContaining('ORGANIZER'), findsOneWidget);
  });

  testWidgets('cria um usuário pelo formulário', (WidgetTester tester) async {
    final api = FakeAuthApi();

    await pumpApp(tester, authApi: api);
    await tester.pumpAndSettle();
    await openUsers(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Novo usuário'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'Mesa Central');
    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'mesa@exemplo.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'segredo123');
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('MESA').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.createUserCalls, 1);
    expect(find.text('Mesa Central'), findsOneWidget);
  });

  testWidgets('organizador não vê o menu de usuários', (WidgetTester tester) async {
    await pumpApp(tester, authApi: FakeAuthApi(), userRole: 'ORGANIZER');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Elenco'), 120);
    expect(find.text('Usuários'), findsNothing);
  });
}
