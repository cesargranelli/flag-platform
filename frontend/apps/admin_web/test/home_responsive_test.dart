import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) {
    final session = InMemorySessionManager()
      ..seedToken('jwt', roles: ['ADMIN'], userName: 'Admin');
    final authApi = FakeAuthApi()
      ..meUser = testUser(role: 'ADMIN');

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

  testWidgets('tela larga exibe cards de acesso em grid',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Usuários'), findsOneWidget);
    expect(find.text('Organizações'), findsOneWidget);
    expect(find.byType(SliverGrid), findsOneWidget);
  });

  testWidgets('tela estreita exibe cards de acesso adaptados',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Organizações'), findsOneWidget);
    expect(find.byType(SliverGrid), findsOneWidget);
  });
}
