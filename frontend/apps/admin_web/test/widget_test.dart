import 'package:flutter_test/flutter_test.dart';

import 'package:flag_admin_web/main.dart';

void main() {
  testWidgets('Admin web renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FlagAdminWeb());

    expect(find.text('Admin Web'), findsOneWidget);
    expect(find.text('Flag Platform'), findsOneWidget);
  });
}
