// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:site_voice_ledger/main.dart';

void main() {
  testWidgets('App splash view smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the splash screen text is displayed.
    expect(find.text('సైట్ వాయిస్ లెడ్జర్'), findsOneWidget);

    // Let the splash timer expire and transition
    await tester.pump(const Duration(seconds: 3));
  });
}
