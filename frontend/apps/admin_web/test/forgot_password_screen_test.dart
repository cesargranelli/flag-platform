import 'package:flag_admin_web/src/app.dart';
import 'package:flag_admin_web/src/providers/providers.dart';
import 'package:flag_admin_web/src/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, FakeAuthApi authApi) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(InMemorySessionManager()),
          authApiProvider.overrideWithValue(authApi),
        ],
        child: const FlagAdminWeb(),
      ),
    );
  }

  testWidgets('solicita link de redefinição e mostra confirmação',
      (WidgetTester tester) async {
    final api = FakeAuthApi();

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Esqueci a senha'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu e-mail para receber o link de redefinição.'),
        findsOneWidget);

    await tester.enterText(
        find.byType(TextFormField), 'org@exemplo.com');
    await tester.tap(find.text('Enviar link de redefinição'));
    await tester.pumpAndSettle();

    expect(api.forgotCalls, 1);
    expect(find.text('Enviamos um link para seu e-mail'), findsOneWidget);
  });

  testWidgets('redefine a senha com o token do link',
      (WidgetTester tester) async {
    final api = FakeAuthApi();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionManagerProvider.overrideWithValue(InMemorySessionManager()),
          authApiProvider.overrideWithValue(api),
        ],
        child: const MaterialApp(
          home: ResetPasswordScreen(token: 'reset-token'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextFormField).at(0), 'nova-senha');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'nova-senha');
    await tester.tap(find.text('Redefinir senha'));
    await tester.pumpAndSettle();

    expect(api.resetCalls, 1);
    expect(find.text('Senha redefinida!'), findsOneWidget);
  });
}
