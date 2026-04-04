import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:planora/main.dart' as app;

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 300),
}) async {
  final maxTicks = timeout.inMilliseconds ~/ step.inMilliseconds;
  for (var i = 0; i < maxTicks; i++) {
    if (condition()) {
      return;
    }
    await tester.pump(step);
  }
  if (!condition()) {
    throw TestFailure('Condition was not met within $timeout.');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create trip and verify suggestions appear in Things to Do tab',
      (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final newTripButton = find.text('New Trip');
    expect(newTripButton, findsOneWidget);
    await tester.tap(newTripButton);
    await tester.pumpAndSettle();

    final tripNameField = find.byType(TextField).first;
    await tester.enterText(tripNameField, 'Madrid');

    final saveButton = find.widgetWithText(FilledButton, 'Save');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Wait for async fetch+save flow after trip creation.
    await tester.pump(const Duration(seconds: 8));

    final madridTrip = find.text('Madrid').first;
    await tester.tap(madridTrip);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final thingsToDoTab = find.text('Things to Do');
    expect(thingsToDoTab, findsOneWidget);
    await tester.tap(thingsToDoTab);

    final emptyMessage =
        find.text('No suggestions yet. Add a city trip while online.');

    await _pumpUntil(
      tester,
      () => emptyMessage.evaluate().isEmpty,
      timeout: const Duration(seconds: 40),
    );

    expect(emptyMessage, findsNothing);
  });
}
