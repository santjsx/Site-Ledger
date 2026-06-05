import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:site_voice_ledger/app_state.dart';
import 'package:site_voice_ledger/views/ledger_list_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LedgerListView filter chips selection and detail hiding test', (WidgetTester tester) async {
    final state = AppState();
    
    // Add a mock site and entry
    await state.loadData();
    await state.addSite('Test Site');
    
    // Multi-component entry: Has labor count, labor paid, owner spent, and note
    await state.addEntry(LedgerEntry(
      id: '1',
      siteId: state.activeSite!.id,
      timestamp: DateTime.now(),
      voiceTranscript: '5 workers, paid 5000, owner spent 1000, note hello',
      labourCount: 5,
      labourPaid: 5000,
      ownerAmount: 1000,
      note: 'cement bag delivered',
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const LedgerListView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Under 'All' (అన్నీ): Verify all metrics are shown
    expect(find.text('"5 workers, paid 5000, owner spent 1000, note hello"'), findsOneWidget);
    expect(find.text('5 మంది కూలీలు'), findsOneWidget);
    expect(find.text('జీతాలు: ₹5,000.00'), findsOneWidget);
    expect(find.text('ఓనర్ ఇచ్చినవి: ₹1,000.00'), findsOneWidget);
    expect(find.text('cement bag delivered'), findsOneWidget);

    // Tap on 'కూలీలు' (Labor)
    await tester.tap(find.text('కూలీలు'));
    await tester.pumpAndSettle();

    // Verify card is shown, but owner spent and notes are hidden visually
    expect(find.text('"5 workers, paid 5000, owner spent 1000, note hello"'), findsOneWidget);
    expect(find.text('5 మంది కూలీలు'), findsOneWidget);
    expect(find.text('జీతాలు: ₹5,000.00'), findsOneWidget);
    expect(find.text('ఓనర్ ఇచ్చినవి: ₹1,000.00'), findsNothing);
    expect(find.text('cement bag delivered'), findsNothing);

    // Tap on 'పైసలు / లెక్కలు' (Financial)
    await tester.tap(find.text('పైసలు / లెక్కలు'));
    await tester.pumpAndSettle();

    // Verify card is shown, owner amount and wages are shown, but worker count and notes are hidden
    expect(find.text('"5 workers, paid 5000, owner spent 1000, note hello"'), findsOneWidget);
    expect(find.text('5 మంది కూలీలు'), findsNothing);
    expect(find.text('జీతాలు: ₹5,000.00'), findsOneWidget);
    expect(find.text('ఓనర్ ఇచ్చినవి: ₹1,000.00'), findsOneWidget);
    expect(find.text('cement bag delivered'), findsNothing);

    // Tap on 'నోట్స్' (Notes)
    await tester.tap(find.text('నోట్స్'));
    await tester.pumpAndSettle();

    // Verify card is shown, notes are shown, but worker count and amounts are hidden
    expect(find.text('"5 workers, paid 5000, owner spent 1000, note hello"'), findsOneWidget);
    expect(find.text('5 మంది కూలీలు'), findsNothing);
    expect(find.text('జీతాలు: ₹5,000.00'), findsNothing);
    expect(find.text('ఓనర్ ఇచ్చినవి: ₹1,000.00'), findsNothing);
    expect(find.text('cement bag delivered'), findsOneWidget);
  });
}
