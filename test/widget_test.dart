import 'package:flutter_test/flutter_test.dart';

import 'package:hoglet/app.dart';

void main() {
  testWidgets('App renders welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HogletApp());

    expect(find.text('Welcome to Hoglet'), findsOneWidget);
  });
}
