import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Game _game() => Game(
      id: 'game-1',
      roundId: 'round-1',
      homeTeamId: 'home-1',
      awayTeamId: 'away-1',
      homeTeamName: 'Tritões',
      awayTeamName: 'Águias',
      scheduledAt: DateTime(2026, 8, 10, 19, 0),
      status: GameStatus.inProgress,
      homeScore: 2,
      awayScore: 1,
    );

ScoreEvent _event(String id, String teamId, DateTime createdAt) => ScoreEvent(
      id: id,
      gameId: 'game-1',
      teamId: teamId,
      createdAt: createdAt,
    );

void main() {
  testWidgets('renderiza vazio quando não há eventos', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ScoreTimeline(game: _game(), events: const [])),
      ),
    );
    expect(find.text('Sequência de pontos'), findsNothing);
  });

  testWidgets('mostra eventos de pontos dos dois times', (WidgetTester tester) async {
    final game = _game();
    final events = [
      _event('e1', 'home-1', DateTime(2026, 8, 10, 19, 5)),
      _event('e2', 'away-1', DateTime(2026, 8, 10, 19, 12)),
      _event('e3', 'home-1', DateTime(2026, 8, 10, 19, 20)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ScoreTimeline(game: game, events: events)),
      ),
    );

    expect(find.textContaining('Ponto'), findsNWidgets(3));
  });
}
