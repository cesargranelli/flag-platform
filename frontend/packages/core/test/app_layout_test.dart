import 'package:flag_core/flag_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLayout define as larguras máximas do padrão web', () {
    expect(AppLayout.maxFormWidth, 600);
    expect(AppLayout.maxDetailWidth, 720);
    expect(AppLayout.maxContentWidth, 1200);
  });

  testWidgets('AppLayout.form centraliza com ConstrainedBox de 600',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      AppLayout.form(child: const SizedBox(width: double.infinity)),
    );

    final box = tester.widget<ConstrainedBox>(
      find.ancestor(
        of: find.byType(SizedBox),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(box.constraints.maxWidth, 600);
    expect(find.byType(Center), findsOneWidget);
  });
}
