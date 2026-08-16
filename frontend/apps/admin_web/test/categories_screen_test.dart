import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required FakeCategoryApi categoryApi,
    FakeCompetitionApi? competitionApi,
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
              FakeOrganizationApi()..organizations = [testOrganization()]),
          competitionApiProvider.overrideWithValue(
              competitionApi ?? FakeCompetitionApi()..competitions = [testCompetition()]),
          categoryApiProvider.overrideWithValue(categoryApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  Future<void> openCategories(WidgetTester tester) async {
    await tester.tap(find.text('Categorias'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista as categorias do campeonato selecionado',
      (WidgetTester tester) async {
    final api = FakeCategoryApi()
      ..categories = [testCategory(name: 'Masculino 5x5'), testCategory(id: '22222222-2222-2222-2222-222222222222', name: 'Feminino 5x5')];

    await pumpApp(tester, categoryApi: api);
    await tester.pumpAndSettle();
    await openCategories(tester);

    expect(find.text('Masculino 5x5'), findsOneWidget);
    expect(find.text('Feminino 5x5'), findsOneWidget);
  });

  testWidgets('troca o campeonato pelo dropdown e lista as categorias',
      (WidgetTester tester) async {
    final api = FakeCategoryApi()
      ..categories = [
        testCategory(name: 'Masculino 5x5'),
        testCategory(
            id: '22222222-2222-2222-2222-222222222222',
            name: 'Feminino 5x5'),
        testCategory(
            id: '33333333-3333-3333-3333-333333333333',
            competitionId: '22222222-2222-2222-2222-222222222222',
            name: 'Sub-17'),
      ];
    final comps = FakeCompetitionApi()
      ..competitions = [
        testCompetition(),
        testCompetition(
            id: '22222222-2222-2222-2222-222222222222',
            name: 'Copa Paulista'),
      ];

    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: ['ORGANIZER'], userName: 'Ana Lima');
    final authApi = FakeAuthApi()..meUser = testUser();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
          organizationApiProvider.overrideWithValue(
              FakeOrganizationApi()..organizations = [testOrganization()]),
          competitionApiProvider.overrideWithValue(comps),
          categoryApiProvider.overrideWithValue(api),
        ],
        child: const FlagAdminWeb(),
      ),
    );
    await tester.pumpAndSettle();
    await openCategories(tester);

    expect(find.text('Masculino 5x5'), findsOneWidget);
    expect(find.text('Sub-17'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copa Paulista').last);
    await tester.pumpAndSettle();

    expect(find.text('Sub-17'), findsOneWidget);
    expect(find.text('Masculino 5x5'), findsNothing);
  });

  testWidgets('cria uma categoria pelo formulário', (WidgetTester tester) async {
    final api = FakeCategoryApi();

    await pumpApp(tester, categoryApi: api);
    await tester.pumpAndSettle();
    await openCategories(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Nova categoria'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taça SP').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'), 'Sub-17');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.createCalls, 1);
    expect(api.lastBody?['name'], 'Sub-17');
    expect(find.text('Sub-17'), findsOneWidget);
  });

  testWidgets('clica em uma categoria e vê a tela de detalhe',
      (WidgetTester tester) async {
    final api = FakeCategoryApi()
      ..categories = [testCategory(name: 'Masculino 5x5')];

    await pumpApp(tester, categoryApi: api);
    await tester.pumpAndSettle();
    await openCategories(tester);

    await tester.tap(find.text('Masculino 5x5'));
    await tester.pumpAndSettle();

    expect(find.text('Editar dados'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('edita uma categoria a partir do detalhe',
      (WidgetTester tester) async {
    final api = FakeCategoryApi()
      ..categories = [testCategory(name: 'Masculino 5x5')];

    await pumpApp(tester, categoryApi: api);
    await tester.pumpAndSettle();
    await openCategories(tester);

    await tester.tap(find.text('Masculino 5x5'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Editar categoria'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'), 'Masculino 6x6');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar dados'), findsOneWidget);
    expect(find.text('Masculino 6x6'), findsWidgets);
  });

  testWidgets('exclui uma categoria a partir do detalhe',
      (WidgetTester tester) async {
    final api = FakeCategoryApi()
      ..categories = [testCategory(name: 'Masculino 5x5')];

    await pumpApp(tester, categoryApi: api);
    await tester.pumpAndSettle();
    await openCategories(tester);

    await tester.tap(find.text('Masculino 5x5'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.textContaining('não pode ser desfeita'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir').last);
    await tester.pumpAndSettle();

    expect(api.deleteCalls, 1);
    expect(find.text('Masculino 5x5'), findsNothing);
  });
}
