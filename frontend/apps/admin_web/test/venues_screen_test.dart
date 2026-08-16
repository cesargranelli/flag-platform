import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    FakeVenueApi venueApi, {
    FakeOrganizationApi? organizationApi,
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
              organizationApi ?? FakeOrganizationApi()..organizations = [testOrganization()]),
          venueApiProvider.overrideWithValue(venueApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  Future<void> openVenues(WidgetTester tester) async {
    await tester.tap(find.text('Campos'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista os campos cadastrados', (WidgetTester tester) async {
    final api = FakeVenueApi()
      ..venues = [
        testVenue(name: 'Arena Paulista'),
        testVenue(id: '22222222-2222-2222-2222-222222222222', name: 'Campo Norte'),
      ];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openVenues(tester);

    expect(find.text('Arena Paulista'), findsOneWidget);
    expect(find.text('Campo Norte'), findsOneWidget);
  });

  testWidgets('cria um campo pelo formulário', (WidgetTester tester) async {
    final api = FakeVenueApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openVenues(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Novo campo'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flag Brasil').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'Arena Central');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.createCalls, 1);
    expect(api.lastBody?['name'], 'Arena Central');
    expect(find.text('Arena Central'), findsOneWidget);
  });

  testWidgets('clica em um campo e vê a tela de detalhe',
      (WidgetTester tester) async {
    final api = FakeVenueApi()..venues = [testVenue(name: 'Arena Paulista')];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openVenues(tester);

    await tester.tap(find.text('Arena Paulista'));
    await tester.pumpAndSettle();

    expect(find.text('Editar dados'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('edita um campo a partir do detalhe',
      (WidgetTester tester) async {
    final api = FakeVenueApi()..venues = [testVenue(name: 'Arena Paulista')];

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openVenues(tester);

    await tester.tap(find.text('Arena Paulista'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Editar campo'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'), 'Arena Central');
    await tester.ensureVisible(find.text('Salvar'));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(api.updateCalls, 1);
    expect(api.lastBody?['name'], 'Arena Central');
    expect(find.text('Editar dados'), findsOneWidget);
    expect(find.text('Arena Central'), findsWidgets);
  });
}
