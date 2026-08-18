import 'package:flag_domain/flag_domain.dart';
import 'package:flag_public_app/src/app.dart';
import 'package:flag_public_app/src/providers/providers.dart';
import 'package:flag_public_app/src/screens/game_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const competitionId = '11111111-1111-1111-1111-111111111111';
const competitionName = 'Liga Nacional';
const roundId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

Game game({
  required String id,
  required DateTime scheduledAt,
  String homeTeamName = 'Flames',
  String awayTeamName = 'Titans',
  int? roundNumber,
  String? venueName,
  String? venueAddress,
  String? venueMapsUrl,
  GameStatus status = GameStatus.scheduled,
  int? homeScore,
  int? awayScore,
}) {
  return Game(
    id: id,
    roundId: roundId,
    roundNumber: roundNumber,
    homeTeamName: homeTeamName,
    awayTeamName: awayTeamName,
    venueName: venueName,
    venueAddress: venueAddress,
    venueMapsUrl: venueMapsUrl,
    scheduledAt: scheduledAt,
    status: status,
    homeScore: homeScore,
    awayScore: awayScore,
  );
}

void main() {
  /// Renderiza a tela de detalhe com o jogo já carregado (via `extra`).
  Future<void> pumpDetail(
    WidgetTester tester,
    Game game, {
    List<ScoreEvent> events = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameDetailProvider.overrideWith((ref, id) async => game),
          gameScoreEventsProvider.overrideWith((ref, id) async => events),
        ],
        child: MaterialApp(
          home: GameDetailScreen(gameId: game.id, game: game),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Sobe o app e navega: home → detalhe → calendário → card do jogo.
  Future<void> openDetailFromCalendar(WidgetTester tester, List<Game> games) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          competitionsProvider.overrideWith(
            (ref) async => [
              Competition(
                id: competitionId,
                name: competitionName,
                status: CompetitionStatus.published,
              ),
            ],
          ),
          competitionGamesProvider.overrideWith((ref, id) async => games),
          gameDetailProvider.overrideWith(
            (ref, id) async => games.firstWhere((g) => g.id == id),
          ),
        ],
        child: const FlagPublicApp(),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(competitionName));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver calendário de jogos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flames × Titans').first);
    await tester.pumpAndSettle();
  }

  group('GameDetailScreen', () {
    testWidgets('renderiza campeonato, times, rodada, horário, status e campo', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        game(
          id: 'game-1',
          roundNumber: 2,
          venueName: 'Arena Central',
          venueAddress: 'Av. das Nações, 100',
          venueMapsUrl: 'https://maps.google.com/?q=Arena+Central',
          scheduledAt: DateTime(2026, 8, 20, 19, 30),
        ),
      );

      expect(find.text('Flames × Titans'), findsOneWidget);
      expect(find.text('Rodada 2'), findsOneWidget);
      expect(find.text('20/08/2026 às 19:30'), findsOneWidget);
      expect(find.text('Agendado'), findsOneWidget);
      expect(find.text('Arena Central'), findsOneWidget);
      expect(find.text('Av. das Nações, 100'), findsOneWidget);
      expect(find.text('Abrir no mapa'), findsOneWidget);
      // Sem nome de campeonato informado, não exibe a linha de campeonato.
      expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
    });

    testWidgets('mostra placar quando o jogo está encerrado', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        game(
          id: 'game-2',
          scheduledAt: DateTime(2026, 8, 10, 15),
          status: GameStatus.finished,
          homeScore: 3,
          awayScore: 2,
        ),
      );

      expect(find.text('Placar final'), findsOneWidget);
      expect(find.text('3 × 2'), findsOneWidget);
      expect(find.text('Encerrado'), findsOneWidget);
    });

    testWidgets('não mostra botão de mapa quando não há link', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        game(id: 'game-3', scheduledAt: DateTime(2026, 8, 20, 19, 30)),
      );

      expect(find.text('Local não informado'), findsOneWidget);
      expect(find.text('Abrir no mapa'), findsNothing);
    });

    testWidgets('busca o jogo por id quando não chega via extra', (
      WidgetTester tester,
    ) async {
      final detail = game(
        id: 'game-4',
        venueName: 'Campo do Parque',
        scheduledAt: DateTime(2026, 8, 20, 19, 30),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameDetailProvider.overrideWith((ref, id) async => detail),
          ],
          child: MaterialApp(
            home: GameDetailScreen(gameId: detail.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flames × Titans'), findsOneWidget);
      expect(find.text('Campo do Parque'), findsOneWidget);
    });

    testWidgets('navega do calendário para o detalhe ao tocar no card', (
      WidgetTester tester,
    ) async {
      await openDetailFromCalendar(
        tester,
        [
          game(
            id: 'game-5',
            roundNumber: 1,
            venueName: 'Campo do Parque',
            scheduledAt: DateTime(2026, 8, 20, 19, 30),
          ),
        ],
      );

      expect(find.text('Flames × Titans'), findsOneWidget);
      expect(find.text('Campo do Parque'), findsOneWidget);
      expect(find.text('Liga Nacional'), findsOneWidget);
      expect(find.text('Abrir no mapa'), findsNothing);
    });

    testWidgets('mostra a timeline de pontos quando há eventos', (
      WidgetTester tester,
    ) async {
      final gameWithIds = Game(
        id: 'game-6',
        roundId: roundId,
        homeTeamId: 'home-1',
        awayTeamId: 'away-1',
        homeTeamName: 'Flames',
        awayTeamName: 'Titans',
        scheduledAt: DateTime(2026, 8, 10, 19, 0),
        status: GameStatus.inProgress,
        homeScore: 2,
        awayScore: 1,
      );
      final events = [
        ScoreEvent(
          id: 'e1',
          gameId: 'game-6',
          teamId: 'home-1',
          createdAt: DateTime(2026, 8, 10, 19, 5),
        ),
        ScoreEvent(
          id: 'e2',
          gameId: 'game-6',
          teamId: 'away-1',
          createdAt: DateTime(2026, 8, 10, 19, 12),
        ),
      ];

      await pumpDetail(tester, gameWithIds, events: events);

      expect(find.text('Sequência de pontos'), findsOneWidget);
      expect(find.textContaining('Ponto'), findsNWidgets(2));
    });
  });
}
