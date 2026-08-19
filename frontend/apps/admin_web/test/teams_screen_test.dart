import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    FakeTeamApi teamApi, {
    FakeCompetitionApi? competitionApi,
    FakeCategoryApi? categoryApi,
  }) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: ['ORGANIZER'], userName: 'Ana Lima');
    final authApi = FakeAuthApi()..meUser = testUser();
    final comps = competitionApi ??
        (FakeCompetitionApi()..competitions = [testCompetition()]);
    final cats = categoryApi ??
        (FakeCategoryApi()
          ..categories = [testCategory(name: 'Masculino 5x5')]);

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
          competitionApiProvider.overrideWithValue(comps),
          categoryApiProvider.overrideWithValue(cats),
          teamApiProvider.overrideWithValue(teamApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  Future<void> openTeams(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Times'), 120);
    await tester.ensureVisible(find.text('Times'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Times'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista os times da categoria', (WidgetTester tester) async {
    final api = FakeTeamApi()
      ..teams = [
        testTeam(name: 'Tritões'),
        testTeam(id: '22222222-2222-2222-2222-222222222222', name: 'Águias'),
      ];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openTeams(tester);

    expect(find.text('Tritões'), findsOneWidget);
    expect(find.text('Águias'), findsOneWidget);
  });

  testWidgets('cria um time pelo formulário', (WidgetTester tester) async {
    final api = FakeTeamApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openTeams(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Novo time'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'Cometas');
    await tester.tap(find.byType(DropdownButtonFormField<DocumentType>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CNPJ').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'CNPJ do time ou CPF do representante'),
        '11.222.333/0001-81');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(api.createCalls, 1);
    expect(api.lastBody?['name'], 'Cometas');
    expect(find.text('Cometas'), findsOneWidget);
  });

  testWidgets('clica em um time e vê a tela de detalhe',
      (WidgetTester tester) async {
    final api = FakeTeamApi()..teams = [testTeam(name: 'Tritões')];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openTeams(tester);

    await tester.tap(find.text('Tritões'));
    await tester.pumpAndSettle();

    expect(find.text('Editar dados'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('edita um time a partir do detalhe',
      (WidgetTester tester) async {
    final api = FakeTeamApi()..teams = [testTeam(name: 'Tritões')];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openTeams(tester);

    await tester.tap(find.text('Tritões'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Editar time'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'), 'Tritões 2026');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.updateCalls, 1);
    expect(api.lastBody?['name'], 'Tritões 2026');
    expect(find.text('Editar dados'), findsOneWidget);
    expect(find.text('Tritões 2026'), findsWidgets);
  });
}
