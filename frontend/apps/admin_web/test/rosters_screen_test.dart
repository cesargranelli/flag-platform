import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required FakeRosterApi rosterApi,
    required FakeAthleteApi athleteApi,
  }) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: ['ORGANIZER'], userName: 'Ana Lima');
    final authApi = FakeAuthApi()..meUser = testUser();

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
          competitionApiProvider.overrideWithValue(
              FakeCompetitionApi()..competitions = [testCompetition()]),
          categoryApiProvider.overrideWithValue(
              FakeCategoryApi()..categories = [testCategory(name: 'Masculino 5x5')]),
          teamApiProvider.overrideWithValue(
              FakeTeamApi()..teams = [testTeam(name: 'Tritões')]),
          athleteApiProvider.overrideWithValue(athleteApi),
          rosterApiProvider.overrideWithValue(rosterApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  Future<void> openRosters(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Elenco'), 120);
    await tester.ensureVisible(find.text('Elenco'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elenco'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista o elenco do time selecionado', (WidgetTester tester) async {
    final roster = FakeRosterApi()
      ..entries = [
        RosterEntry(
          id: '11111111-1111-1111-1111-111111111111',
          teamId: '11111111-1111-1111-1111-111111111111',
          athleteId: '22222222-2222-2222-2222-222222222222',
          athleteName: 'João Silva',
          number: 7,
          status: 'ACTIVE',
        ),
      ];

    await pumpApp(tester, rosterApi: roster, athleteApi: FakeAthleteApi());
    await tester.pumpAndSettle();
    await openRosters(tester);

    expect(find.text('João Silva'), findsOneWidget);
    expect(find.textContaining('Camisa 7'), findsOneWidget);
  });

  testWidgets('inscreve um atleta pelo diálogo', (WidgetTester tester) async {
    final roster = FakeRosterApi();
    final athletes = FakeAthleteApi()
      ..athletes = [testAthlete(name: 'João Silva')];

    await pumpApp(tester, rosterApi: roster, athleteApi: athletes);
    await tester.pumpAndSettle();
    await openRosters(tester);

    await tester.tap(find.byIcon(Icons.person_add_alt_1));
    await tester.pumpAndSettle();

    final dialogDropdown = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(DropdownButtonFormField<String>),
    );
    await tester.tap(dialogDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('João Silva').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(roster.addCalls, 1);
  });
}
