import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    FakeOrganizationApi organizationApi,
  ) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: ['ORGANIZER'], userName: 'Ana Lima');
    final authApi = FakeAuthApi()..meUser = testUser();

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
          organizationApiProvider.overrideWithValue(organizationApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  Future<void> openOrganizations(WidgetTester tester) async {
    await tester.tap(find.text('Organizações'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista as organizações cadastradas',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi()
      ..organizations = [testOrganization(), testOrganization(id: '22222222-2222-2222-2222-222222222222', tradeName: 'Liga Sul')];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await openOrganizations(tester);

    expect(find.text('Flag Brasil'), findsOneWidget);
    expect(find.text('Liga Sul'), findsOneWidget);
  });

  testWidgets('mostra estado vazio quando não há organizações',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await openOrganizations(tester);

    expect(find.text('Nenhuma organização cadastrada'), findsOneWidget);
  });

  testWidgets('cria uma nova organização pelo formulário',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openOrganizations(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Nova organização'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Copa Interior');
    await tester.enterText(find.byType(TextFormField).at(1), 'Liga do Interior');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.createCalls, 1);
    expect(api.lastBody?['tradeName'], 'Copa Interior');
    expect(find.text('Copa Interior'), findsOneWidget);
  });

  testWidgets('edita uma organização existente',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi()
      ..organizations = [testOrganization()];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openOrganizations(tester);

    await tester.tap(find.text('Flag Brasil'));
    await tester.pumpAndSettle();

    expect(find.text('Editar organização'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).at(0)).controller?.text,
      'Flag Brasil',
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Flag Brasil 2026');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.updateCalls, 1);
    expect(api.lastBody?['tradeName'], 'Flag Brasil 2026');
  });
}
