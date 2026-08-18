import 'package:flag_domain/flag_domain.dart';
import 'package:flag_referee_app/src/app.dart';
import 'package:flag_referee_app/src/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required FakeGameApi gameApi,
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
        ],
        child: const FlagRefereeApp(),
      ),
    );
  }

  Future<void> openOperation(WidgetTester tester) async {
    await tester.tap(find.text('Operar partida'));
    await tester.pumpAndSettle();
  }

  testWidgets('inicia a partida com confirmação (IN_PROGRESS)',
      (WidgetTester tester) async {
    final api = FakeGameApi()..games = [testGame()];

    await pumpApp(tester, gameApi: api);
    await tester.pumpAndSettle();
    await openOperation(tester);

    expect(find.text('Iniciar partida'), findsOneWidget);

    await tester.tap(find.text('Iniciar partida'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar partida'), findsWidgets); // título do diálogo
    expect(find.textContaining('agora?'), findsOneWidget);

    await tester.tap(find.text('Iniciar').last);
    await tester.pumpAndSettle();

    expect(api.lastStatus, GameStatus.inProgress);
  });

  testWidgets('finaliza a partida com confirmação (FINISHED)',
      (WidgetTester tester) async {
    final api = FakeGameApi()
      ..games = [testGame(status: GameStatus.inProgress)];

    await pumpApp(tester, gameApi: api);
    await tester.pumpAndSettle();
    await openOperation(tester);

    expect(find.text('Finalizar partida'), findsOneWidget);

    await tester.ensureVisible(find.text('Finalizar partida'));
    await tester.tap(find.text('Finalizar partida'));
    await tester.pumpAndSettle();

    expect(find.text('Tem certeza que deseja finalizar esta partida?'),
        findsOneWidget);

    await tester.tap(find.text('Finalizar').last);
    await tester.pumpAndSettle();

    expect(api.lastStatus, GameStatus.finished);
  });
}
