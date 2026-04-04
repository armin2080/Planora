import 'package:flutter_test/flutter_test.dart';

import 'package:planora/app.dart';

void main() {
  testWidgets('Planora app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const PlanoraApp());
    expect(find.text('Planora'), findsOneWidget);
    expect(find.text('New Trip'), findsOneWidget);
  });
}
