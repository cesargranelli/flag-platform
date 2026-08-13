import 'dart:async';

import 'package:flag_domain/flag_domain.dart';
import 'package:flag_public_app/src/app.dart';
import 'package:flag_public_app/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required List<Override> overrides,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const FlagPublicApp(),
      ),
    );
  }

  Competition competition({
    required String id,
    required String name,
    CompetitionStatus status = CompetitionStatus.published,
    String? organizationName,
  }) {
    return Competition(
      id: id,
      name: name,
      status: status,
      organizationName: organizationName,
    );
  }

  group('HomeScreen', () {
    testWidgets('mostra loading enquanto a lista carrega',
        (WidgetTester tester) async {
      final never = Completer<List<Competition>>();

      await pumpApp(tester, overrides: [
        competitionsProvider.overrideWith((ref) => never.future),
      ]);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando campeonatos...'), findsOneWidget);
    });

    testWidgets('renderiza nome, organização e status de cada campeonato',
        (WidgetTester tester) async {
      final competitions = [
        competition(
          id: '11111111-1111-1111-1111-111111111111',
          name: 'Liga Nacional',
          organizationName: 'Flag Brasil',
        ),
        competition(
          id: '22222222-2222-2222-2222-222222222222',
          name: 'Torneio Regional',
          status: CompetitionStatus.draft,
          organizationName: 'Liga Sul',
        ),
        competition(
          id: '33333333-3333-3333-3333-333333333333',
          name: 'Copa Encerramento',
          status: CompetitionStatus.finished,
          organizationName: 'Federação Paulista',
        ),
      ];

      await pumpApp(tester, overrides: [
        competitionsProvider.overrideWith((ref) async => competitions),
      ]);
      await tester.pump();

      expect(find.text('Liga Nacional'), findsOneWidget);
      expect(find.text('Flag Brasil'), findsOneWidget);
      expect(find.text('Torneio Regional'), findsOneWidget);
      expect(find.text('Liga Sul'), findsOneWidget);
      expect(find.text('Copa Encerramento'), findsOneWidget);
      expect(find.text('Federação Paulista'), findsOneWidget);

      // Rótulos pt-BR dos status.
      expect(find.text('Em andamento'), findsOneWidget);
      expect(find.text('Rascunho'), findsOneWidget);
      expect(find.text('Encerrado'), findsOneWidget);
    });

    testWidgets('mostra estado vazio quando não há campeonatos',
        (WidgetTester tester) async {
      await pumpApp(tester, overrides: [
        competitionsProvider.overrideWith((ref) async => <Competition>[]),
      ]);
      await tester.pump();

      expect(find.text('Nenhum campeonato disponível'), findsOneWidget);
      expect(find.byIcon(Icons.sports_football), findsOneWidget);
    });

    testWidgets('mostra erro e permite tentar novamente',
        (WidgetTester tester) async {
      var shouldFail = true;
      final competitions = [
        competition(
          id: '11111111-1111-1111-1111-111111111111',
          name: 'Liga Nacional',
          organizationName: 'Flag Brasil',
        ),
      ];

      await pumpApp(tester, overrides: [
        competitionsProvider.overrideWith((ref) async {
          if (shouldFail) {
            throw Exception('falha de rede');
          }
          return competitions;
        }),
      ]);
      await tester.pump();

      expect(
        find.text('Não foi possível carregar os campeonatos'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);

      // Ao tocar, o provider é invalidado e a lista carrega.
      shouldFail = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Liga Nacional'), findsOneWidget);
      expect(find.text('Flag Brasil'), findsOneWidget);
    });

    testWidgets('navega para o detalhe ao tocar num card',
        (WidgetTester tester) async {
      final competitions = [
        competition(
          id: '11111111-1111-1111-1111-111111111111',
          name: 'Liga Nacional',
          organizationName: 'Flag Brasil',
        ),
      ];

      await pumpApp(tester, overrides: [
        competitionsProvider.overrideWith((ref) async => competitions),
      ]);
      await tester.pump();

      await tester.tap(find.text('Liga Nacional'));
      await tester.pumpAndSettle();

      // Tela de detalhe mostra o nome do campeonato.
      expect(find.text('Campeonato'), findsOneWidget);
      expect(find.text('Liga Nacional'), findsOneWidget);
    });
  });
}
