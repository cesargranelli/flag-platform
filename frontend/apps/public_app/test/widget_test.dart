import 'package:flutter_test/flutter_test.dart';

import 'package:flag_public_app/main.dart';

void main() {
  testWidgets('Public app renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FlagPublicApp());

    expect(find.text('Public App'), findsOneWidget);
    expect(find.text('Flag Platform'), findsOneWidget);
  });
}
