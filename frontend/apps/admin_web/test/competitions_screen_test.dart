import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required FakeCompetitionApi competitionApi,
    FakeOrganizationApi? organizationApi,
  }) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: ['ORGANIZER'], userName: 'Ana Lima');
    final authApi = FakeAuthApi()..meUser = testUser();

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
          organizationApiProvider.overrideWithValue(
              organizationApi ?? FakeOrganizationApi()..organizations = [testOrganization()]),
          competitionApiProvider.overrideWithValue(competitionApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  Future<void> openCompetitions(WidgetTester tester) async {
    await tester.tap(find.text('Campeonatos'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista os campeonatos', (WidgetTester tester) async {
    final api = FakeCompetitionApi()
      ..competitions = [
        testCompetition(name: 'Taça SP'),
        testCompetition(id: '33333333-3333-3333-3333-333333333333', name: 'Copa Paulista'),
      ];

    await pumpApp(tester, competitionApi: api);
    await tester.pumpAndSettle();

    await openCompetitions(tester);

    expect(find.text('Taça SP'), findsOneWidget);
    expect(find.text('Copa Paulista'), findsOneWidget);
  });

  testWidgets('botão de voltar retorna para a home', (WidgetTester tester) async {
    await pumpApp(tester, competitionApi: FakeCompetitionApi());
    await tester.pumpAndSettle();

    await openCompetitions(tester);
    expect(find.text('Campeonatos'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo, Ana Lima!'), findsOneWidget);
    expect(find.text('Nenhum campeonato cadastrado'), findsNothing);
  });

  testWidgets('mostra estado vazio quando não há campeonatos',
      (WidgetTester tester) async {
    await pumpApp(tester, competitionApi: FakeCompetitionApi());
    await tester.pumpAndSettle();

    await openCompetitions(tester);

    expect(find.text('Nenhum campeonato cadastrado'), findsOneWidget);
  });

  testWidgets('cria um campeonato pelo formulário', (WidgetTester tester) async {
    final api = FakeCompetitionApi();

    await pumpApp(tester, competitionApi: api);
    await tester.pumpAndSettle();
    await openCompetitions(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Novo campeonato'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flag Brasil').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'), 'Taça SP 2026');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.createCalls, 1);
    expect(api.lastBody?['name'], 'Taça SP 2026');
    expect(find.text('Taça SP 2026'), findsOneWidget);
  });

  testWidgets('clica em um campeonato e vê a tela de detalhe',
      (WidgetTester tester) async {
    final api = FakeCompetitionApi()..competitions = [testCompetition()];

    await pumpApp(tester, competitionApi: api);
    await tester.pumpAndSettle();
    await openCompetitions(tester);

    await tester.tap(find.text('Taça SP'));
    await tester.pumpAndSettle();

    expect(find.text('Editar dados'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('edita um campeonato a partir do detalhe',
      (WidgetTester tester) async {
    final api = FakeCompetitionApi()..competitions = [testCompetition()];

    await pumpApp(tester, competitionApi: api);
    await tester.pumpAndSettle();
    await openCompetitions(tester);

    await tester.tap(find.text('Taça SP'));
    await tester.pumpAndSettle();

    expect(find.text('Editar dados'), findsOneWidget);
    await tester.tap(find.text('Editar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Editar campeonato'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'), 'Taça SP 2026');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.updateCalls, 1);
    expect(api.lastBody?['name'], 'Taça SP 2026');
    expect(find.text('Editar dados'), findsOneWidget);
  });
}
