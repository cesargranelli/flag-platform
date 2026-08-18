import 'package:flag_domain/flag_domain.dart';
import 'package:flag_referee_app/src/app.dart';
import 'package:flag_referee_app/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required FakeGameApi gameApi,
    required FakeCheckInApi checkInApi,
  }) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: ['MESA'], userName: 'Mesa Central');
    final authApi = FakeAuthApi()..meUser = testUser();

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
          competitionApiProvider.overrideWithValue(
              FakeCompetitionApi()..competitions = [testCompetition()]),
          categoryApiProvider.overrideWithValue(
              FakeCategoryApi()..categories = [testCategory()]),
          roundApiProvider.overrideWithValue(
              FakeRoundApi()..rounds = [testRound()]),
          gameApiProvider.overrideWithValue(gameApi),
          checkInApiProvider.overrideWithValue(checkInApi),
        ],
        child: const FlagRefereeApp(),
      ),
    );
  }

  Future<void> openCheckIn(WidgetTester tester) async {
    await tester.tap(find.text('Check-in de atletas'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista o roster do jogo no pré-jogo', (WidgetTester tester) async {
    final api = FakeCheckInApi()..entries = [testCheckIn()];

    await pumpApp(
      tester,
      gameApi: FakeGameApi()..games = [testGame()],
      checkInApi: api,
    );
    await tester.pumpAndSettle();
    await openCheckIn(tester);

    expect(find.text('João Silva'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
  });

  testWidgets('marca PRESENT no pré-jogo', (WidgetTester tester) async {
    final api = FakeCheckInApi()..entries = [testCheckIn()];

    await pumpApp(
      tester,
      gameApi: FakeGameApi()..games = [testGame()],
      checkInApi: api,
    );
    await tester.pumpAndSettle();
    await openCheckIn(tester);

    await tester.tap(find.byIcon(Icons.check_circle));
    await tester.pumpAndSettle();

    expect(api.lastStatus, CheckInStatus.present);
  });

  testWidgets('mostra feedback de atleta fora do roster na validação',
      (WidgetTester tester) async {
    final api = FakeCheckInApi()
      ..entries = [testCheckIn()]
      ..validateResult = CheckInStatus.notRegistered;

    await pumpApp(
      tester,
      gameApi: FakeGameApi()..games = [testGame(status: GameStatus.inProgress)],
      checkInApi: api,
    );
    await tester.pumpAndSettle();
    await openCheckIn(tester);

    await tester.tap(find.text('Validar'));
    await tester.pumpAndSettle();

    expect(find.text('João Silva não está no roster'), findsOneWidget);
  });

  testWidgets('exibe override de numeração com badge do oficial',
      (WidgetTester tester) async {
    final api = FakeCheckInApi()
      ..entries = [
        testCheckIn(number: 10, athleteNumber: 7, matchNumber: 10),
      ];

    await pumpApp(
      tester,
      gameApi: FakeGameApi()..games = [testGame()],
      checkInApi: api,
    );
    await tester.pumpAndSettle();
    await openCheckIn(tester);

    expect(find.textContaining('Camisa 10'), findsOneWidget);
    expect(find.textContaining('oficial 7'), findsOneWidget);
  });

  testWidgets('define numeração de partida via diálogo',
      (WidgetTester tester) async {
    final api = FakeCheckInApi()..entries = [testCheckIn()];

    await pumpApp(
      tester,
      gameApi: FakeGameApi()..games = [testGame()],
      checkInApi: api,
    );
    await tester.pumpAndSettle();
    await openCheckIn(tester);

    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Numeração da partida'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '10');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.lastMatchNumber, 10);
  });

  testWidgets('limpa numeração de partida (volta ao oficial)',
      (WidgetTester tester) async {
    final api = FakeCheckInApi()..entries = [testCheckIn()];

    await pumpApp(
      tester,
      gameApi: FakeGameApi()..games = [testGame()],
      checkInApi: api,
    );
    await tester.pumpAndSettle();
    await openCheckIn(tester);

    await tester.tap(find.byIcon(Icons.tag_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.lastMatchNumber, isNull);
  });
}
