import 'package:flag_domain/flag_domain.dart';
import 'package:flag_public_app/src/app.dart';
import 'package:flag_public_app/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const competitionId = '11111111-1111-1111-1111-111111111111';
const competitionName = 'Liga Nacional';
const roundId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

Game game({
  required String id,
  required int roundNumber,
  required DateTime scheduledAt,
  String homeTeamName = 'Flames',
  String awayTeamName = 'Titans',
  String? venueName,
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
    scheduledAt: scheduledAt,
    status: status,
    homeScore: homeScore,
    awayScore: awayScore,
  );
}

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) {
    return tester.pumpWidget(
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
          ...overrides,
        ],
        child: const FlagPublicApp(),
      ),
    );
  }

  /// Sobe o app e navega: home → detalhe → resultados.
  Future<void> openResults(
    WidgetTester tester, {
    List<Game> games = const [],
  }) async {
    await pumpApp(
      tester,
      overrides: [
        competitionGamesProvider.overrideWith((ref, id) async => games),
      ],
    );
    await tester.pump();
    await tester.tap(find.text(competitionName));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver resultados'));
    await tester.pumpAndSettle();
  }

  group('CompetitionResultsScreen', () {
    testWidgets('navega do detalhe para os resultados ao tocar no botão', (
      WidgetTester tester,
    ) async {
      await openResults(
        tester,
        games: [
          game(
            id: 'game-1',
            roundNumber: 1,
            scheduledAt: DateTime(2026, 8, 1, 10),
            status: GameStatus.finished,
            homeScore: 3,
            awayScore: 1,
          ),
        ],
      );

      // AppBar com o nome do campeonato + conteúdo dos resultados.
      expect(find.text(competitionName), findsOneWidget);
      expect(find.text('Flames × Titans'), findsOneWidget);
      expect(find.text('Placar: 3 × 1'), findsOneWidget);
    });

    testWidgets('exibe apenas jogos encerrados, com rodada, campo e placar', (
      WidgetTester tester,
    ) async {
      final games = [
        game(
          id: 'game-1',
          roundNumber: 1,
          homeTeamName: 'Flames',
          awayTeamName: 'Titans',
          venueName: 'Campo do Parque',
          scheduledAt: DateTime(2026, 8, 20, 19, 30),
          status: GameStatus.finished,
          homeScore: 3,
          awayScore: 1,
        ),
        game(
          id: 'game-2',
          roundNumber: 2,
          scheduledAt: DateTime(2026, 8, 21, 15, 0),
        ),
        game(
          id: 'game-3',
          roundNumber: 2,
          scheduledAt: DateTime(2026, 8, 22, 15, 0),
          status: GameStatus.inProgress,
          homeScore: 0,
          awayScore: 0,
        ),
      ];

      await openResults(tester, games: games);

      // Apenas o jogo encerrado aparece, com rodada junto ao horário.
      expect(find.text('Rodada 1 · 20/08/2026 19:30'), findsOneWidget);
      expect(find.text('Flames × Titans'), findsOneWidget);
      expect(find.text('Campo: Campo do Parque'), findsOneWidget);
      expect(find.text('Placar: 3 × 1'), findsOneWidget);
      expect(find.text('Encerrado'), findsOneWidget);

      // Agendado e ao vivo não são resultados.
      expect(find.text('21/08/2026 15:00'), findsNothing);
      expect(find.text('22/08/2026 15:00'), findsNothing);
      expect(find.text('Ao vivo'), findsNothing);
    });

    testWidgets('ordena os resultados do mais recente para o mais antigo', (
      WidgetTester tester,
    ) async {
      final games = [
        game(
          id: 'game-1',
          roundNumber: 1,
          homeTeamName: 'Flames',
          awayTeamName: 'Titans',
          scheduledAt: DateTime(2026, 7, 10, 10),
          status: GameStatus.finished,
          homeScore: 1,
          awayScore: 0,
        ),
        game(
          id: 'game-2',
          roundNumber: 2,
          homeTeamName: 'Falcons',
          awayTeamName: 'Eagles',
          scheduledAt: DateTime(2026, 8, 5, 10),
          status: GameStatus.finished,
          homeScore: 2,
          awayScore: 2,
        ),
        game(
          id: 'game-3',
          roundNumber: 3,
          homeTeamName: 'Foxes',
          awayTeamName: 'Wolves',
          scheduledAt: DateTime(2026, 9, 1, 10),
          status: GameStatus.finished,
          homeScore: 4,
          awayScore: 2,
        ),
      ];

      await openResults(tester, games: games);

      // O jogo mais recente (setembro) deve aparecer acima dos demais.
      final newestY = tester
          .getTopLeft(find.text('Foxes × Wolves'))
          .dy;
      final middleY = tester.getTopLeft(find.text('Falcons × Eagles')).dy;
      final oldestY = tester.getTopLeft(find.text('Flames × Titans')).dy;

      expect(newestY, lessThan(middleY));
      expect(middleY, lessThan(oldestY));
    });

    testWidgets('navega para o detalhe do jogo ao tocar no card', (
      WidgetTester tester,
    ) async {
      await openResults(
        tester,
        games: [
          game(
            id: 'game-1',
            roundNumber: 1,
            homeTeamName: 'Flames',
            awayTeamName: 'Titans',
            venueName: 'Campo do Parque',
            scheduledAt: DateTime(2026, 8, 20, 19, 30),
            status: GameStatus.finished,
            homeScore: 3,
            awayScore: 1,
          ),
        ],
      );

      await tester.tap(find.text('Flames × Titans'));
      await tester.pumpAndSettle();

      // Detalhe: placar final, campo e campeonato carregados via `extra`.
      expect(find.text('Placar final'), findsOneWidget);
      expect(find.text('3 × 1'), findsOneWidget);
      expect(find.text('Campo do Parque'), findsOneWidget);
      expect(find.text('Liga Nacional'), findsOneWidget);
      expect(find.text('Encerrado'), findsOneWidget);
    });

    testWidgets('mostra estado vazio quando não há jogos encerrados', (
      WidgetTester tester,
    ) async {
      await openResults(
        tester,
        games: [
          game(
            id: 'game-1',
            roundNumber: 1,
            scheduledAt: DateTime(2026, 8, 1, 10),
          ),
        ],
      );

      expect(find.text('Nenhum resultado disponível'), findsOneWidget);
      expect(find.byIcon(Icons.sports_score_outlined), findsOneWidget);
    });

    testWidgets('mostra erro e permite tentar novamente', (
      WidgetTester tester,
    ) async {
      var shouldFail = true;
      final games = [
        game(
          id: 'game-1',
          roundNumber: 1,
          scheduledAt: DateTime(2026, 8, 1, 10),
          status: GameStatus.finished,
          homeScore: 2,
          awayScore: 1,
        ),
      ];

      await pumpApp(
        tester,
        overrides: [
          competitionGamesProvider.overrideWith((ref, id) async {
            if (shouldFail) {
              throw Exception('falha de rede');
            }
            return games;
          }),
        ],
      );
      await tester.pump();
      await tester.tap(find.text(competitionName));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver resultados'));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar os resultados'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);

      // Ao tocar, o provider é invalidado e os resultados carregam.
      shouldFail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Flames × Titans'), findsOneWidget);
      expect(find.text('Placar: 2 × 1'), findsOneWidget);
    });
  });
}
