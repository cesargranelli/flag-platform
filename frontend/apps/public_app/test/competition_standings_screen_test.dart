import 'package:flag_domain/flag_domain.dart';
import 'package:flag_public_app/src/app.dart';
import 'package:flag_public_app/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const competitionId = '11111111-1111-1111-1111-111111111111';
const competitionName = 'Liga Nacional';
const maleCategoryId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const femaleCategoryId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

Category category({
  required String id,
  required String name,
}) {
  return Category(
    id: id,
    competitionId: competitionId,
    modalityId: '11111111-1111-1111-1111-111111111111',
    gender: Gender.male,
    ageGroup: AgeGroup.adult,
    name: name,
  );
}

Standing standing({
  required int position,
  required String teamId,
  required String teamName,
  required int played,
  required int wins,
  required int losses,
  required int goalDifference,
  required int points,
}) {
  return Standing(
    position: position,
    teamId: teamId,
    teamName: teamName,
    played: played,
    wins: wins,
    draws: 0,
    losses: losses,
    goalsFor: 0,
    goalsAgainst: 0,
    goalDifference: goalDifference,
    points: points,
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

  /// Sobe o app e navega: home → detalhe → classificação.
  Future<void> openStandings(
    WidgetTester tester, {
    List<Category> categories = const [],
    Map<String, List<Standing>> standingsByCategory = const {},
  }) async {
    await pumpApp(
      tester,
      overrides: [
        competitionCategoriesProvider.overrideWith(
          (ref, id) async => categories,
        ),
        categoryStandingsProvider.overrideWith(
          (ref, categoryId) async =>
              standingsByCategory[categoryId] ?? const [],
        ),
      ],
    );
    await tester.pump();
    await tester.tap(find.text(competitionName));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver classificação'));
    await tester.pumpAndSettle();
  }

  group('CompetitionStandingsScreen', () {
    testWidgets('navega do detalhe para a classificação ao tocar no botão', (
      WidgetTester tester,
    ) async {
      await openStandings(
        tester,
        categories: [
          category(id: maleCategoryId, name: 'Masculino'),
        ],
        standingsByCategory: {
          maleCategoryId: [
            standing(
              position: 1,
              teamId: 'team-1',
              teamName: 'Flames',
              played: 6,
              wins: 5,
              losses: 0,
              goalDifference: 16,
              points: 16,
            ),
          ],
        },
      );

      expect(find.text(competitionName), findsOneWidget);
      expect(find.text('Flames'), findsOneWidget);
    });

    testWidgets('exibe a tabela com posição, time, PJ, V, D, SG e PTS', (
      WidgetTester tester,
    ) async {
      await openStandings(
        tester,
        categories: [
          category(id: maleCategoryId, name: 'Masculino'),
        ],
        standingsByCategory: {
          maleCategoryId: [
            standing(
              position: 1,
              teamId: 'team-1',
              teamName: 'Flames',
              played: 6,
              wins: 5,
              losses: 0,
              goalDifference: 16,
              points: 16,
            ),
            standing(
              position: 2,
              teamId: 'team-2',
              teamName: 'Titans',
              played: 6,
              wins: 4,
              losses: 1,
              goalDifference: -3,
              points: 13,
            ),
          ],
        },
      );

      // Cabeçalho da tabela.
      expect(find.text('Pos'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('PJ'), findsOneWidget);
      expect(find.text('V'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('SG'), findsOneWidget);
      expect(find.text('PTS'), findsOneWidget);

      // Linhas: time + valores (SG formatado com sinal).
      expect(find.text('Flames'), findsOneWidget);
      expect(find.text('Titans'), findsOneWidget);
      expect(find.text('+16'), findsOneWidget);
      expect(find.text('-3'), findsOneWidget);
      expect(find.text('16'), findsWidgets);
      expect(find.text('13'), findsOneWidget);
    });

    testWidgets('destaca o time na primeira posição com troféu', (
      WidgetTester tester,
    ) async {
      await openStandings(
        tester,
        categories: [
          category(id: maleCategoryId, name: 'Masculino'),
        ],
        standingsByCategory: {
          maleCategoryId: [
            standing(
              position: 1,
              teamId: 'team-1',
              teamName: 'Flames',
              played: 6,
              wins: 5,
              losses: 0,
              goalDifference: 16,
              points: 16,
            ),
            standing(
              position: 2,
              teamId: 'team-2',
              teamName: 'Titans',
              played: 6,
              wins: 4,
              losses: 1,
              goalDifference: 8,
              points: 13,
            ),
          ],
        },
      );

      // Líder com troféu no lugar do número da posição; demais com número.
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('alterna a tabela ao selecionar outra categoria', (
      WidgetTester tester,
    ) async {
      await openStandings(
        tester,
        categories: [
          category(id: maleCategoryId, name: 'Masculino'),
          category(id: femaleCategoryId, name: 'Feminino'),
        ],
        standingsByCategory: {
          maleCategoryId: [
            standing(
              position: 1,
              teamId: 'team-1',
              teamName: 'Flames',
              played: 6,
              wins: 5,
              losses: 0,
              goalDifference: 16,
              points: 16,
            ),
          ],
          femaleCategoryId: [
            standing(
              position: 1,
              teamId: 'team-3',
              teamName: 'Eagles',
              played: 4,
              wins: 4,
              losses: 0,
              goalDifference: 10,
              points: 12,
            ),
          ],
        },
      );

      // Chips das categorias; primeira selecionada por padrão.
      expect(find.text('Masculino'), findsOneWidget);
      expect(find.text('Feminino'), findsOneWidget);
      expect(find.text('Flames'), findsOneWidget);

      await tester.tap(find.text('Feminino'));
      await tester.pumpAndSettle();

      expect(find.text('Eagles'), findsOneWidget);
      expect(find.text('Flames'), findsNothing);
    });

    testWidgets('atualiza ao puxar para baixo (pull to refresh)', (
      WidgetTester tester,
    ) async {
      var standingsCalls = 0;
      var categoriesCalls = 0;

      await pumpApp(
        tester,
        overrides: [
          competitionCategoriesProvider.overrideWith((ref, id) async {
            categoriesCalls++;
            return [
              category(id: maleCategoryId, name: 'Masculino'),
            ];
          }),
          categoryStandingsProvider.overrideWith((ref, categoryId) async {
            standingsCalls++;
            return [
              standing(
                position: 1,
                teamId: 'team-1',
                teamName: 'Flames',
                played: 6,
                wins: 5,
                losses: 0,
                goalDifference: 16,
                points: 16,
              ),
            ];
          }),
        ],
      );
      await tester.pump();
      await tester.tap(find.text(competitionName));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver classificação'));
      await tester.pumpAndSettle();

      expect(standingsCalls, 1);
      expect(categoriesCalls, 1);

      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(standingsCalls, 2);
      expect(categoriesCalls, 2);
    });

    testWidgets('mostra estado vazio quando não há classificação', (
      WidgetTester tester,
    ) async {
      await openStandings(
        tester,
        categories: [
          category(id: maleCategoryId, name: 'Masculino'),
        ],
      );

      expect(find.text('Nenhuma classificação disponível'), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard_outlined), findsOneWidget);
    });

    testWidgets('mostra erro e permite tentar novamente', (
      WidgetTester tester,
    ) async {
      var shouldFail = true;
      final categories = [category(id: maleCategoryId, name: 'Masculino')];
      final standings = [
        standing(
          position: 1,
          teamId: 'team-1',
          teamName: 'Flames',
          played: 6,
          wins: 5,
          losses: 0,
          goalDifference: 16,
          points: 16,
        ),
      ];

      await pumpApp(
        tester,
        overrides: [
          competitionCategoriesProvider.overrideWith(
            (ref, id) async => categories,
          ),
          categoryStandingsProvider.overrideWith((ref, categoryId) async {
            if (shouldFail) {
              throw Exception('falha de rede');
            }
            return standings;
          }),
        ],
      );
      await tester.pump();
      await tester.tap(find.text(competitionName));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver classificação'));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar a classificação'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);

      // Ao tocar, o provider é invalidado e a tabela carrega.
      shouldFail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Flames'), findsOneWidget);
    });
  });
}
