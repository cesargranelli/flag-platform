import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    FakeOrganizationApi organizationApi,
  ) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: ['ORGANIZER'], userName: 'Ana Lima');
    final authApi = FakeAuthApi()..meUser = testUser();

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
          organizationApiProvider.overrideWithValue(organizationApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  Future<void> openOrganizations(WidgetTester tester) async {
    await tester.tap(find.text('Organizações'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista as organizações cadastradas',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi()
      ..organizations = [testOrganization(), testOrganization(id: '22222222-2222-2222-2222-222222222222', tradeName: 'Liga Sul')];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await openOrganizations(tester);

    expect(find.text('Flag Brasil'), findsOneWidget);
    expect(find.text('Liga Sul'), findsOneWidget);
  });

  testWidgets('mostra estado vazio quando não há organizações',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await openOrganizations(tester);

    expect(find.text('Nenhuma organização cadastrada'), findsOneWidget);
  });

  testWidgets('cria uma nova organização pelo formulário',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openOrganizations(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Nova organização'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Copa Interior');
    await tester.enterText(find.byType(TextFormField).at(1), 'Liga do Interior');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'CNPJ (opcional)'),
        '11.222.333/0001-81');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do presidente'), 'Maria Silva');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'CPF do presidente'), '123.456.789-09');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.createCalls, 1);
    expect(api.lastBody?['tradeName'], 'Copa Interior');
    expect(api.lastBody?['documentType'], 'CNPJ');
    expect(api.lastBody?['presidentName'], 'Maria Silva');
    expect(find.text('Copa Interior'), findsOneWidget);
  });

  testWidgets('clica em uma organização e vê a tela de detalhe',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi()
      ..organizations = [testOrganization()];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openOrganizations(tester);

    await tester.tap(find.text('Flag Brasil'));
    await tester.pumpAndSettle();

    expect(find.text('Editar dados'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('edita uma organização a partir do detalhe',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi()
      ..organizations = [testOrganization()];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openOrganizations(tester);

    await tester.tap(find.text('Flag Brasil'));
    await tester.pumpAndSettle();

    expect(find.text('Editar dados'), findsOneWidget);
    await tester.tap(find.text('Editar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Editar organização'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).at(0)).controller?.text,
      'Flag Brasil',
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Flag Brasil 2026');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.updateCalls, 1);
    expect(api.lastBody?['tradeName'], 'Flag Brasil 2026');
    expect(find.text('Flag Brasil 2026'), findsWidgets);
    expect(find.text('Editar dados'), findsOneWidget);
  });

  testWidgets('confirma descarte ao sair com alterações não salvas',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openOrganizations(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Copa Interior');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Descartar alterações?'), findsOneWidget);

    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();

    expect(find.text('Nova organização'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(find.text('Nova organização'), findsNothing);
  });

testWidgets('troca o campo de estado para texto ao escolher outro país',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openOrganizations(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Copa Interior');
    await tester.enterText(find.byType(TextFormField).at(1), 'Liga do Interior');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do presidente'), 'Maria Silva');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'CPF do presidente'), '123.456.789-09');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Estado (opcional)'), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));

    await tester.ensureVisible(
        find.byType(DropdownButtonFormField<String>).first);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estados Unidos').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Estado (opcional)'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('abre o seletor de cor e aplica o valor no campo hex',
      (WidgetTester tester) async {
    final api = FakeOrganizationApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openOrganizations(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Copa Interior');
    await tester.enterText(find.byType(TextFormField).at(1), 'Liga do Interior');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do presidente'), 'Maria Silva');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'CPF do presidente'), '123.456.789-09');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Prévia da marca'), findsOneWidget);

    await tester.tap(find.byTooltip('Escolher cor').first);
    await tester.pumpAndSettle();

    expect(find.text('Escolher cor'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'FF0000',
    );
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    final primaryField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Cor primária (opcional)'),
    );
    expect(primaryField.controller?.text, '#FF0000');
  });
}

