import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    FakeAthleteApi athleteApi, {
    FakeRosterApi? rosterApi,
  }) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: ['ORGANIZER'], userName: 'Ana Lima');
    final authApi = FakeAuthApi()..meUser = testUser();

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
          athleteApiProvider.overrideWithValue(athleteApi),
          rosterApiProvider.overrideWithValue(rosterApi ?? FakeRosterApi()),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  testWidgets('lista os atletas cadastrados', (WidgetTester tester) async {
    final api = FakeAthleteApi()
      ..athletes = [
        testAthlete(name: 'João Silva'),
        testAthlete(id: '22222222-2222-2222-2222-222222222222', name: 'Bia Santos'),
      ];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Atletas'), 120);
    await tester.ensureVisible(find.text('Atletas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atletas'));
    await tester.pumpAndSettle();

    expect(find.text('João Silva'), findsOneWidget);
    expect(find.text('Bia Santos'), findsOneWidget);
  });

  testWidgets('cria um atleta pelo formulário', (WidgetTester tester) async {
    final api = FakeAthleteApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Atletas'), 120);
    await tester.ensureVisible(find.text('Atletas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atletas'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Novo atleta'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'Carlos');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.createCalls, 1);
    expect(api.lastBody?['name'], 'Carlos');
    expect(find.text('Carlos'), findsOneWidget);
  });

  testWidgets('clica em um atleta e vê a tela de detalhe',
      (WidgetTester tester) async {
    final api = FakeAthleteApi()..athletes = [testAthlete(name: 'João Silva')];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Atletas'), 120);
    await tester.ensureVisible(find.text('Atletas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atletas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('João Silva'));
    await tester.pumpAndSettle();

    expect(find.text('Editar dados'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('edita um atleta a partir do detalhe',
      (WidgetTester tester) async {
    final api = FakeAthleteApi()..athletes = [testAthlete(name: 'João Silva')];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Atletas'), 120);
    await tester.ensureVisible(find.text('Atletas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atletas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('João Silva'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Editar atleta'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'), 'João Silva Jr');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.updateCalls, 1);
    expect(api.lastBody?['name'], 'João Silva Jr');
    expect(find.text('Editar dados'), findsOneWidget);
  });
}
