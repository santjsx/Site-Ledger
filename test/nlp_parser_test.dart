import 'package:flutter_test/flutter_test.dart';
import 'package:site_voice_ledger/speech_handler.dart';

void main() {
  test('LedgerNlpParser parses digits correctly', () {
    final entry = LedgerNlpParser.parse('5 workers, paid 5000, owner spent 1500, note tiles');
    expect(entry.labourCount, 5);
    expect(entry.labourPaid, 5000.0);
    expect(entry.ownerAmount, 1500.0);
    expect(entry.note, 'tiles');
  });

  test('LedgerNlpParser parses casual Telugu words and numerals correctly', () {
    final entry = LedgerNlpParser.parse('కూలీలు ఐదుగురు జీతాలు ఐదు వేలు ఓనర్ ఖర్చు రెండు వేల ఐదు వందలు');
    expect(entry.labourCount, 5);
    expect(entry.labourPaid, 5000.0);
    expect(entry.ownerAmount, 2500.0); // 2000 + 500 = 2500, or normalized
  });

  test('LedgerNlpParser handles casual sentences correctly', () {
    // "లేబర్ 3 మందికి 1500 ఇచ్చాము, ఓనర్ ఖర్చు 1000"
    final entry = LedgerNlpParser.parse('లేబర్ ముగ్గురికి 1500 ఇచ్చాము ఓనర్ ఖర్చు వెయ్యి నోట్ సిమెంట్');
    expect(entry.labourCount, 3);
    expect(entry.labourPaid, 1500.0);
    expect(entry.ownerAmount, 1000.0);
    expect(entry.note, 'సిమెంట్');
  });

  test('LedgerNlpParser handles sentence from user screenshot correctly', () {
    final entry = LedgerNlpParser.parse('ఈరోజు కూలీలు ముగ్గురు జీతం 2000 ఓనర్ 5000 ఇచ్చాడు');
    expect(entry.labourCount, 3);
    expect(entry.labourPaid, 2000.0);
    expect(entry.ownerAmount, 5000.0);
  });

  test('LedgerNlpParser handles general text as notes if no metrics match', () {
    final entry = LedgerNlpParser.parse('ఈరోజు ఇసుక వచ్చింది');
    expect(entry.labourCount, null);
    expect(entry.labourPaid, null);
    expect(entry.ownerAmount, null);
    expect(entry.note, 'ఈరోజు ఇసుక వచ్చింది');
  });

  test('LedgerNlpParser parses Telugu amounts with suffix and prefix keywords correctly', () {
    final entry1 = LedgerNlpParser.parse('కూలీలకు 1200 ఇచ్చాము');
    expect(entry1.labourPaid, 1200.0);

    final entry2 = LedgerNlpParser.parse('ఓనర్ 3000 ఖర్చు చేశారు');
    expect(entry2.ownerAmount, 3000.0);
  });

  test('LedgerNlpParser parses money given by owner in English and Telugu', () {
    final entry1 = LedgerNlpParser.parse('owner gave 5000');
    expect(entry1.ownerAmount, 5000.0);

    final entry2 = LedgerNlpParser.parse('ఓనర్ ఐదు వేలు ఇచ్చారు');
    expect(entry2.ownerAmount, 5000.0);

    final entry3 = LedgerNlpParser.parse('ఓనర్ అడ్వాన్స్ రెండు వేలు పంపించారు');
    expect(entry3.ownerAmount, 2000.0);
  });
}
