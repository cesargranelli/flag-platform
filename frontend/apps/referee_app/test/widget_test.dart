import 'package:flutter_test/flutter_test.dart';

import 'package:flag_referee_app/main.dart';

void main() {
  testWidgets('Referee app renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FlagRefereeApp());

    expect(find.text('Referee App'), findsOneWidget);
    expect(find.text('Flag Platform'), findsOneWidget);
  });
}
