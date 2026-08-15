import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    FakeRoundApi roundApi, {
    FakeCompetitionApi? competitionApi,
    FakeCategoryApi? categoryApi,
  }) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: ['ORGANIZER'], userName: 'Ana Lima');
    final authApi = FakeAuthApi()..meUser = testUser();
    final comps = competitionApi ??
        (FakeCompetitionApi()..competitions = [testCompetition()]);
    final cats = categoryApi ??
        (FakeCategoryApi()..categories = [testCategory(name: 'Masculino 5x5')]);

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
          competitionApiProvider.overrideWithValue(comps),
          categoryApiProvider.overrideWithValue(cats),
          roundApiProvider.overrideWithValue(roundApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  Future<void> openRounds(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Rodadas'), 120);
    await tester.ensureVisible(find.text('Rodadas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rodadas'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista as rodadas da categoria', (WidgetTester tester) async {
    final api = FakeRoundApi()
      ..rounds = [
        testRound(name: 'Primeira Rodada'),
        testRound(id: '22222222-2222-2222-2222-222222222222', number: 2, name: 'Segunda Rodada'),
      ];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openRounds(tester);

    expect(find.textContaining('Primeira Rodada'), findsOneWidget);
    expect(find.textContaining('Segunda Rodada'), findsOneWidget);
  });

  testWidgets('cria uma rodada pelo formulário', (WidgetTester tester) async {
    final api = FakeRoundApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openRounds(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Nova rodada'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Número'), '3');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'Terceira Rodada');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.createCalls, 1);
    expect(api.lastBody?['name'], 'Terceira Rodada');
    expect(api.lastBody?['number'], 3);
    expect(find.textContaining('Terceira Rodada'), findsOneWidget);
  });
}
