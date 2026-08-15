import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, FakeAuthApi authApi) {
    final session = InMemorySessionManager();
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

  Future<void> openSignup(WidgetTester tester) async {
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
  }

  testWidgets('cria conta e mostra estado de pendência',
      (WidgetTester tester) async {
    final api = FakeAuthApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();
    await openSignup(tester);

    expect(find.text('Solicite acesso como organizador.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'org@exemplo.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo123');
    await tester.enterText(find.byType(TextFormField).at(2), 'segredo123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(api.registerCalls, 1);
    expect(api.users.last.email, 'org@exemplo.com');
    expect(find.text('Conta criada!'), findsOneWidget);
    expect(find.textContaining('aprovação de um administrador'), findsOneWidget);
  });

  testWidgets('valida senhas diferentes', (WidgetTester tester) async {
    await pumpApp(tester, FakeAuthApi());
    await tester.pumpAndSettle();
    await openSignup(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'org@exemplo.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo123');
    await tester.enterText(find.byType(TextFormField).at(2), 'outra-senha');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('As senhas não coincidem'), findsOneWidget);
  });
}
