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

  /// Sobe o app e navega: home → detalhe → calendário de jogos.
  Future<void> openCalendar(
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
    await tester.tap(find.text('Ver calendário de jogos'));
    await tester.pumpAndSettle();
  }

  group('CompetitionGamesScreen', () {
    testWidgets('navega do detalhe para o calendário ao tocar no botão', (
      WidgetTester tester,
    ) async {
      await openCalendar(
        tester,
        games: [
          game(
            id: 'game-1',
            roundNumber: 1,
            scheduledAt: DateTime(2025, 8, 1, 10),
          ),
        ],
      );

      // AppBar com o nome do campeonato + conteúdo do calendário.
      expect(find.text(competitionName), findsOneWidget);
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Flames × Titans'), findsOneWidget);
    });

    testWidgets('renderiza times, horário, campo e status de cada jogo', (
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
          roundNumber: 1,
          homeTeamName: 'Falcons',
          awayTeamName: 'Eagles',
          scheduledAt: DateTime(2026, 8, 21, 15, 0),
          status: GameStatus.cancelled,
        ),
      ];

      await openCalendar(tester, games: games);

      // Horários formatados dd/MM/yyyy HH:mm.
      expect(find.text('20/08/2026 19:30'), findsOneWidget);
      expect(find.text('21/08/2026 15:00'), findsOneWidget);
      // Times e campo.
      expect(find.text('Flames × Titans'), findsOneWidget);
      expect(find.text('Falcons × Eagles'), findsOneWidget);
      expect(find.text('Campo: Campo do Parque'), findsOneWidget);
      expect(find.text('Local não informado'), findsOneWidget);
      // Status: encerrado (com placar) e cancelado.
      expect(find.text('Encerrado'), findsOneWidget);
      expect(find.text('Placar: 3 × 1'), findsOneWidget);
      expect(find.text('Cancelado'), findsOneWidget);
    });

    testWidgets('filtra a lista pela rodada selecionada', (
      WidgetTester tester,
    ) async {
      final games = [
        game(
          id: 'game-1',
          roundNumber: 1,
          homeTeamName: 'Flames',
          awayTeamName: 'Titans',
          scheduledAt: DateTime(2025, 8, 1, 10),
        ),
        game(
          id: 'game-2',
          roundNumber: 2,
          homeTeamName: 'Falcons',
          awayTeamName: 'Eagles',
          scheduledAt: DateTime(2025, 8, 8, 10),
        ),
        game(
          id: 'game-3',
          roundNumber: 3,
          homeTeamName: 'Foxes',
          awayTeamName: 'Wolves',
          scheduledAt: DateTime(2025, 8, 15, 10),
        ),
      ];

      await openCalendar(tester, games: games);

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Rodada 1'), findsOneWidget);
      expect(find.text('Rodada 2'), findsOneWidget);
      expect(find.text('Rodada 3'), findsOneWidget);
      expect(find.text('Flames × Titans'), findsOneWidget);
      expect(find.text('Falcons × Eagles'), findsOneWidget);
      expect(find.text('Foxes × Wolves'), findsOneWidget);

      await tester.tap(find.text('Rodada 2'));
      await tester.pumpAndSettle();

      expect(find.text('Flames × Titans'), findsNothing);
      expect(find.text('Falcons × Eagles'), findsOneWidget);
      expect(find.text('Foxes × Wolves'), findsNothing);

      // Volta para "Todas".
      await tester.tap(find.text('Todas'));
      await tester.pumpAndSettle();

      expect(find.text('Flames × Titans'), findsOneWidget);
      expect(find.text('Foxes × Wolves'), findsOneWidget);
    });

    testWidgets('destaca os próximos jogos agendados na seção Próximos jogos', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final games = [
        game(
          id: 'game-1',
          roundNumber: 1,
          homeTeamName: 'Flames',
          awayTeamName: 'Titans',
          scheduledAt: now.subtract(const Duration(days: 2)),
          status: GameStatus.finished,
          homeScore: 1,
          awayScore: 0,
        ),
        game(
          id: 'game-2',
          roundNumber: 2,
          homeTeamName: 'Falcons',
          awayTeamName: 'Eagles',
          scheduledAt: now.add(const Duration(days: 2)),
        ),
        game(
          id: 'game-3',
          roundNumber: 3,
          homeTeamName: 'Foxes',
          awayTeamName: 'Wolves',
          scheduledAt: now.add(const Duration(days: 5)),
        ),
        game(
          id: 'game-4',
          roundNumber: 3,
          homeTeamName: 'Lions',
          awayTeamName: 'Bears',
          scheduledAt: now.add(const Duration(days: 4)),
          status: GameStatus.inProgress,
        ),
      ];

      await openCalendar(tester, games: games);

      // Seção de destaque com os agendados futuros (até 3).
      expect(find.text('Próximos jogos'), findsOneWidget);
      expect(find.text('Todos os jogos'), findsOneWidget);
      expect(find.text('Próximo'), findsNWidgets(2));

      // Rola até o fim para conferir os cards da lista completa.
      await tester.dragUntilVisible(
        find.text('Ao vivo'),
        find.byType(ListView),
        const Offset(0, -100),
      );

      // Ao vivo (futuro, mas em andamento) e encerrado só na lista completa.
      expect(find.text('Ao vivo'), findsOneWidget);
      expect(find.text('Encerrado'), findsOneWidget);
      // Jogos agendados futuros também aparecem na lista completa.
      expect(find.text('Falcons × Eagles'), findsAtLeastNWidgets(1));
      expect(find.text('Foxes × Wolves'), findsAtLeastNWidgets(1));
    });

    testWidgets('limita o destaque de próximos jogos a 3', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final games = [
        for (var i = 1; i <= 5; i++)
          game(
            id: 'game-$i',
            roundNumber: 1,
            homeTeamName: 'Time $i',
            awayTeamName: 'Rival $i',
            scheduledAt: now.add(Duration(days: i)),
          ),
      ];

      await openCalendar(tester, games: games);

      // Apenas os 3 mais próximos entram no destaque.
      expect(find.text('Próximos jogos'), findsOneWidget);
      expect(find.text('Próximo'), findsNWidgets(3));

      // Os demais agendados ficam apenas na lista completa.
      await tester.dragUntilVisible(
        find.text('Time 5 × Rival 5'),
        find.byType(ListView),
        const Offset(0, -100),
      );
      expect(find.text('Time 4 × Rival 4'), findsAtLeastNWidgets(1));
      expect(find.text('Time 5 × Rival 5'), findsAtLeastNWidgets(1));
    });

    testWidgets('mostra estado vazio quando não há jogos', (
      WidgetTester tester,
    ) async {
      await openCalendar(tester, games: const []);

      expect(find.text('Nenhum jogo disponível'), findsOneWidget);
      expect(find.byIcon(Icons.sports_football), findsOneWidget);
    });

    testWidgets('mostra erro e permite tentar novamente', (
      WidgetTester tester,
    ) async {
      var shouldFail = true;
      final games = [
        game(
          id: 'game-1',
          roundNumber: 1,
          scheduledAt: DateTime(2025, 8, 1, 10),
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
      await tester.tap(find.text('Ver calendário de jogos'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar os jogos'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      // Ao tocar, o provider é invalidado e o calendário carrega.
      shouldFail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Flames × Titans'), findsOneWidget);
    });
  });
}
