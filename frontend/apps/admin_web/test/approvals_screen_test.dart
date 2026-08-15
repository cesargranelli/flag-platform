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
    required FakeAuthApi authApi,
    String userRole = 'ADMIN',
  }) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: [userRole], userName: 'Admin');
    authApi.meUser = User(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Admin',
      email: 'admin@exemplo.com',
      role: userRole,
    );

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(session),
          authApiProvider.overrideWithValue(authApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  Future<void> openApprovals(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Aprovações'), 120);
    await tester.ensureVisible(find.text('Aprovações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aprovações'));
    await tester.pumpAndSettle();
  }

  testWidgets('lista pendências e aprova uma conta', (WidgetTester tester) async {
    final api = FakeAuthApi()
      ..pending = [
        User(
          id: 'p1',
          name: 'org',
          email: 'org@exemplo.com',
          role: 'ORGANIZER',
          status: 'PENDING',
        ),
      ];

    await pumpApp(tester, authApi: api);
    await tester.pumpAndSettle();
    await openApprovals(tester);

    expect(find.text('org@exemplo.com'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check_circle));
    await tester.pumpAndSettle();

    expect(api.approveCalls, 1);
    expect(find.text('Nenhuma conta aguardando aprovação'), findsOneWidget);
  });

  testWidgets('rejeita uma conta', (WidgetTester tester) async {
    final api = FakeAuthApi()
      ..pending = [
        User(
          id: 'p2',
          name: 'org',
          email: 'org2@exemplo.com',
          role: 'ORGANIZER',
          status: 'PENDING',
        ),
      ];

    await pumpApp(tester, authApi: api);
    await tester.pumpAndSettle();
    await openApprovals(tester);

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();

    expect(api.rejectCalls, 1);
    expect(find.text('Nenhuma conta aguardando aprovação'), findsOneWidget);
  });

  testWidgets('organizador não vê o menu de aprovações',
      (WidgetTester tester) async {
    await pumpApp(tester, authApi: FakeAuthApi(), userRole: 'ORGANIZER');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Elenco'), 120);
    expect(find.text('Aprovações'), findsNothing);
  });
}
