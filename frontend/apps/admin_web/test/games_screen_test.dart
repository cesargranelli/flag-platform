import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    FakeGameApi gameApi, {
    FakeCompetitionApi? competitionApi,
    FakeCategoryApi? categoryApi,
    FakeRoundApi? roundApi,
    FakeTeamApi? teamApi,
    FakeVenueApi? venueApi,
  }) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: ['ORGANIZER'], userName: 'Ana Lima');
    final authApi = FakeAuthApi()..meUser = testUser();

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
          competitionApiProvider.overrideWithValue(
              competitionApi ?? FakeCompetitionApi()..competitions = [testCompetition()]),
          categoryApiProvider.overrideWithValue(
              categoryApi ?? FakeCategoryApi()..categories = [testCategory(name: 'Masculino 5x5')]),
          roundApiProvider.overrideWithValue(
              roundApi ?? FakeRoundApi()..rounds = [testRound()]),
          teamApiProvider.overrideWithValue(teamApi ?? FakeTeamApi()),
          venueApiProvider.overrideWithValue(venueApi ?? FakeVenueApi()),
          gameApiProvider.overrideWithValue(gameApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  Future<void> openGames(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Jogos'), 120);
    await tester.ensureVisible(find.text('Jogos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jogos'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista os jogos da rodada', (WidgetTester tester) async {
    final api = FakeGameApi()..games = [testGame()];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openGames(tester);

    expect(find.text('Agendado'), findsOneWidget);
  });

  testWidgets('cria um jogo pelo formulário', (WidgetTester tester) async {
    final api = FakeGameApi();
    final teams = FakeTeamApi()
      ..teams = [
        testTeam(name: 'Tritões'),
        testTeam(id: '33333333-3333-3333-3333-333333333333', name: 'Águias'),
      ];

    await pumpApp(tester, api, teamApi: teams);
    await tester.pumpAndSettle();
    await openGames(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Novo jogo'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tritões').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Águias').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.createCalls, 1);
    expect(api.lastBody?['homeTeamId'], isNotEmpty);
    expect(api.lastBody?['awayTeamId'], isNotEmpty);
  });

  testWidgets('clica em um jogo e vê a tela de detalhe',
      (WidgetTester tester) async {
    final api = FakeGameApi()
      ..games = [
        testGame(
          homeTeamName: 'Tritões',
          awayTeamName: 'Águias',
        ),
      ];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openGames(tester);

    await tester.tap(find.text('Tritões x Águias'));
    await tester.pumpAndSettle();

    expect(find.text('Editar dados'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('abre a tela de importação de jogos e vê o modelo CSV',
      (WidgetTester tester) async {
    final api = FakeGameApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openGames(tester);

    await tester.tap(find.byIcon(Icons.upload_file));
    await tester.pumpAndSettle();

    expect(find.text('Importar jogos'), findsOneWidget);
    expect(find.text('Ver modelo CSV'), findsOneWidget);
    expect(find.text('Selecionar arquivo'), findsOneWidget);

    await tester.tap(find.text('Ver modelo CSV'));
    await tester.pumpAndSettle();

    expect(find.text('Modelo CSV'), findsOneWidget);
    expect(
      find.textContaining('time_casa;time_fora;campo;data;hora'),
      findsOneWidget,
    );
  });
}
