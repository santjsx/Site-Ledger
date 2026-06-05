import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ParsedEntry {
  final int? labourCount;
  final double? ownerAmount;
  final double? labourPaid;
  final String? note;
  final String? cleanedTranscript;

  ParsedEntry({
    this.labourCount,
    this.ownerAmount,
    this.labourPaid,
    this.note,
    this.cleanedTranscript,
  });
}

class LedgerNlpParser {
  static String _normalizeNumbers(String text) {
    var result = text.toLowerCase();

    // Map of Telugu word numbers to digits
    final Map<String, String> wordToDigit = {
      'ఒక్కరు': '1',
      'ఒకరు': '1',
      'ఒకటి': '1',
      'ఒక్క': '1',
      'ఇద్దరు': '2',
      'ఇద్దరికి': '2',
      'రెండు': '2',
      'ముగ్గురు': '3',
      'ముగ్గురికి': '3',
      'మూడు': '3',
      'నలుగురు': '4',
      'నలుగురికి': '4',
      'నాలుగు': '4',
      'ఐదుగురు': '5',
      'ఐదుగురికి': '5',
      'ఐదు': '5',
      'ఆరుగురు': '6',
      'ఆరుగురికి': '6',
      'ఆరు': '6',
      'ఏడుగురు': '7',
      'ఏడుగురికి': '7',
      'ఏడు': '7',
      'ఎనిమిది మంది': '8',
      'ఎనిమిదిగురు': '8',
      'ఎనిమిదిగురికి': '8',
      'ఎనిమిది': '8',
      'తొమ్మిది మంది': '9',
      'తొమ్మిదిగురు': '9',
      'తొమ్మిదిగురికి': '9',
      'తొమ్మిది': '9',
      'పది మంది': '10',
      'పదిగురు': '10',
      'పదిగురికి': '10',
      'పది': '10',
      'పదకొండు': '11',
      'పన్నెండు': '12',
      'పదమూడు': '13',
      'పద్నాలుగు': '14',
      'పదిహేను': '15',
      'పదహారు': '16',
      'పదిహేడు': '17',
      'పద్దెనిమిది': '18',
      'పంతొమ్మిది': '19',
      'ఇరవై': '20',
      'ముప్పై': '30',
      'నలభై': '40',
      'యాభై': '50',
      'అరవై': '60',
      'డెబ్బై': '70',
      'ఎనభై': '80',
      'తొంభై': '90',
      'వందల': '100',
      'వందలు': '100',
      'వంద': '100',
      'వెయ్యి': '1000',
      'వేయి': '1000',
      'లక్షల': '100000',
      'లక్షలు': '100000',
      'లక్ష': '100000',
    };

    final Map<String, String> englishWordToDigit = {
      'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5',
      'six': '6', 'seven': '7', 'eight': '8', 'nine': '9', 'ten': '10',
      'eleven': '11', 'twelve': '12', 'thirteen': '13', 'fourteen': '14',
      'fifteen': '15', 'twenty': '20', 'thirty': '30', 'forty': '40',
      'fifty': '50', 'hundred': '100', 'thousand': '1000', 'lakh': '100000'
    };

    // First replace compound phrases like "రెండు వేల ఐదు వందలు" (2500)
    final compoundRegex = RegExp(r'(\d+|ఒక్క|ఒక|రెండు|మూడు|నాలుగు|ఐదు|ఆరు|ఏడు|ఎనిమిది|తొమ్మిది|పది|పదకొండు|పన్నెండు|పదిహేను|ఇరవై|యాభై)\s*వేల\s*(\d+|ఒక్క|ఒక|రెండు|మూడు|నాలుగు|ఐదు|ఆరు|ఏడు|ఎనిమిది|తొమ్మిది|పది)\s*వందల?(ు)?');
    result = result.replaceAllMapped(compoundRegex, (match) {
      final thousandsPart = match.group(1)!;
      final hundredsPart = match.group(2)!;
      
      double thousands = 0;
      if (RegExp(r'^\d+$').hasMatch(thousandsPart)) {
        thousands = double.parse(thousandsPart);
      } else {
        thousands = double.tryParse(wordToDigit[thousandsPart] ?? '0') ?? 0;
      }

      double hundreds = 0;
      if (RegExp(r'^\d+$').hasMatch(hundredsPart)) {
        hundreds = double.parse(hundredsPart);
      } else {
        hundreds = double.tryParse(wordToDigit[hundredsPart] ?? '0') ?? 0;
      }

      return (thousands * 1000 + hundreds * 100).toInt().toString();
    });

    // Replace multipliers with prefixes next (single multipliers like "ఐదు వేలు")
    final teMultipliers = [
      {'word': 'లక్షల', 'value': 100000},
      {'word': 'లక్షలు', 'value': 100000},
      {'word': 'లక్ష', 'value': 100000},
      {'word': 'వేల', 'value': 1000},
      {'word': 'వేయి', 'value': 1000},
      {'word': 'వేలు', 'value': 1000},
      {'word': 'వందల', 'value': 100},
      {'word': 'వందలు', 'value': 100},
      {'word': 'వంద', 'value': 100},
    ];

    final enMultipliers = [
      {'word': 'lakhs', 'value': 100000},
      {'word': 'lakh', 'value': 100000},
      {'word': 'thousand', 'value': 1000},
      {'word': 'hundred', 'value': 100},
    ];

    for (var mult in teMultipliers) {
      final String word = mult['word'] as String;
      final int value = mult['value'] as int;
      final regex = RegExp(r'(\d+|ఒక్క|ఒక|రెండు|మూడు|నాలుగు|ఐదు|ఆరు|ఏడు|ఎనిమిది|తొమ్మిది|పది|ఇరవై|యాభై)\s*' '$word');
      result = result.replaceAllMapped(regex, (match) {
        final prefix = match.group(1)!;
        double factor = 1;
        if (RegExp(r'^\d+$').hasMatch(prefix)) {
          factor = double.parse(prefix);
        } else {
          final digitStr = wordToDigit[prefix] ?? '1';
          factor = double.tryParse(digitStr) ?? 1;
        }
        return (factor * value).toInt().toString();
      });
    }

    for (var mult in enMultipliers) {
      final String word = mult['word'] as String;
      final int value = mult['value'] as int;
      final regex = RegExp(r'(\d+|one|two|three|four|five|six|seven|eight|nine|ten|twenty|fifty)\s*' '$word');
      result = result.replaceAllMapped(regex, (match) {
        final prefix = match.group(1)!;
        double factor = 1;
        if (RegExp(r'^\d+$').hasMatch(prefix)) {
          factor = double.parse(prefix);
        } else {
          final digitStr = englishWordToDigit[prefix] ?? '1';
          factor = double.tryParse(digitStr) ?? 1;
        }
        return (factor * value).toInt().toString();
      });
    }

    // Sort keys by length in descending order to avoid partial sub-word replacement
    final sortedKeys = wordToDigit.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (var key in sortedKeys) {
      final digit = wordToDigit[key]!;
      result = result.replaceAll(key, digit);
    }

    final sortedEnglishKeys = englishWordToDigit.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (var key in sortedEnglishKeys) {
      final digit = englishWordToDigit[key]!;
      final regex = RegExp('\\b$key\\b');
      result = result.replaceAll(regex, digit);
    }

    return result;
  }

  static ParsedEntry parse(String text) {
    // Preprocess text by normalizing Telugu and English spoken numbers to digits
    final normalizedText = _normalizeNumbers(text);
    final lowerText = normalizedText.toLowerCase();
    
    int? labourCount;
    double? ownerAmount;
    double? labourPaid;
    String? note;

    // 1. Parse Labour Count
    final labourCountRegExs = [
      RegExp(r'(?:labour|labor)\s+count\s*[:\s\-]*\s*(\d+)'),
      RegExp(r'(?:కార్మికులు|కార్మికుల\s+సంఖ్య|లేబర్|లేబర్\s+కౌంట్|కూలీలు|కూలీల\s+సంఖ్య)\s*[:\s\-]*\s*(\d+)'),
      RegExp(r'(\d+)\s*(?:worker|labor|labour|people|మంది|మనుషులు)s?'),
      RegExp(r'count\s*[:\s\-]*\s*(\d+)'),
    ];

    for (var reg in labourCountRegExs) {
      final match = reg.firstMatch(lowerText);
      if (match != null) {
        labourCount = int.tryParse(match.group(1) ?? '');
        if (labourCount != null) break;
      }
    }

    // 2. Parse Money Given by Owner (Owner Advance/Cash Inflow)
    final ownerRegExs = [
      RegExp(r'owner\s*(?:gave|sent|received|advance|spent|amount)?\s*[:\s\-]*\s*(\d+(?:\.\d+)?)'),
      RegExp(r'(?:యజమాని|ఓనర్)\s*(?:ఇచ్చినవి|పంపినవి|అడ్వాన్స్|ఇచ్చారు|ఇచ్చిన|ఖర్చు|మొత్తం|అమౌంట్)?\s*[:\s\-]*\s*(\d+(?:\.\d+)?)'),
      RegExp(r'owner\s*[:\s\-]*\s*(\d+(?:\.\d+)?)'),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:given|sent|advance|spent)?\s*(?:by\s+)?owner'),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:యజమాని|ఓనర్)\s*(?:ఇచ్చారు|ఇచ్చినవి|పంపినవి|అడ్వాన్స్|ఇచ్చిన|ఖర్చు)'),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:యజమాని|ఓనర్|ఓనర్\s*ది|ఓనర్\s*ఖర్చు)'),
    ];

    for (var reg in ownerRegExs) {
      final match = reg.firstMatch(lowerText);
      if (match != null) {
        ownerAmount = double.tryParse(match.group(1) ?? '');
        if (ownerAmount != null) break;
      }
    }

    // 3. Parse Labour Paid
    final labourPaidRegExs = [
      RegExp(r'(?:labour|labor)\s+paid\s*[:\s\-]*\s*(\d+(?:\.\d+)?)'),
      RegExp(r'(?:కార్మికులకు\s+చెల్లించిన\s+మొత్తం|చెల్లింపులు|కార్మికుల\s+జీతం|జీతాలు|లేబర్\s+పేమెంట్|కూలీల\s+ఖర్చు|కూలీల\s+డబ్బులు|కూలి|కూలి\s+డబ్బులు|కూలీలకు)\s*[:\s\-]*\s*(\d+(?:\.\d+)?)'),
      RegExp(r'paid\s*[:\s\-]*\s*(\d+(?:\.\d+)?)'),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:labor|labour|లేబర్)?\s*paid'),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:చెల్లించాము|ఇచ్చాము|జీతం|చెల్లింపు|డబ్బులు|కూలి|కూలీలకు|కూలి\s*డబ్బులు)'),
    ];

    for (var reg in labourPaidRegExs) {
      final match = reg.firstMatch(lowerText);
      if (match != null) {
        final val = double.tryParse(match.group(1) ?? '');
        if (val != null) {
          labourPaid = val;
          break;
        }
      }
    }

    // 4. Parse Note
    final noteRegExs = [
      RegExp(r'(?:note|remark|notes|comment|గమనిక|నోట్|వ్యాఖ్య|వివరం)s?\s*[:\s\-]*\s*(.+)'),
    ];

    for (var reg in noteRegExs) {
      final match = reg.firstMatch(text);
      if (match != null) {
        note = match.group(1)?.trim();
        break;
      }
    }

    if (note == null && labourCount == null && ownerAmount == null && labourPaid == null && text.trim().isNotEmpty) {
      final ledgerKeywords = [
        'worker', 'labor', 'labour', 'people', 'paid', 'owner', 'spent', 'amount', 'gave', 'sent', 'received', 'advance',
        'cost', 'wages', 'cash', 'rupees', 'rs',
        'కార్మికులు', 'కార్మికుల', 'లేబర్', 'కూలీలు', 'కూలీల', 'మంది', 'మనుషులు',
        'జీతం', 'జీతాలు', 'డబ్బులు', 'కూలి', 'కూలీలకు', 'పేమెంట్', 'చెల్లించాము', 'ఇచ్చాము', 'ఇచ్చారు',
        'యజమాని', 'ఓనర్', 'ఖర్చు', 'మొత్తం', 'అమౌంట్', 'ఇచ్చిన', 'ఇచ్చినవి', 'పంపినవి', 'అడ్వాన్స్', 'రూపాయలు'
      ];
      final lower = text.toLowerCase();
      bool hasLedgerKeywords = ledgerKeywords.any((keyword) => lower.contains(keyword));
      if (!hasLedgerKeywords) {
        note = text.trim();
      }
    }

    return ParsedEntry(
      labourCount: labourCount,
      ownerAmount: ownerAmount,
      labourPaid: labourPaid,
      note: note,
      cleanedTranscript: text,
    );
  }
}

class SpeechHandler {
  // Singleton pattern
  static final SpeechHandler _instance = SpeechHandler._internal();
  factory SpeechHandler() => _instance;
  SpeechHandler._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  String _lastError = '';

  Function(String)? _onStatus;
  Function(String)? _onError;
  Function()? _activeOnDone;
  bool _wasListening = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _speechToText.isListening;
  String get lastError => _lastError;

  Future<bool> initialize({
    required Function(String) onStatus,
    required Function(String) onError,
  }) async {
    _onStatus = onStatus;
    _onError = onError;

    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          if (_onStatus != null) _onStatus!(status);
          if (status == 'listening') {
            _wasListening = true;
          }
          if (status == 'notListening' || status == 'done') {
            if (_wasListening) {
              _wasListening = false;
              if (_activeOnDone != null) {
                final done = _activeOnDone;
                _activeOnDone = null; // Clear it to avoid duplicate calls
                done!();
              }
            }
          }
        },
        onError: (errorNotification) {
          _lastError = errorNotification.errorMsg;
          if (_onError != null) _onError!(errorNotification.errorMsg);
        },
      );
    } catch (e) {
      _lastError = e.toString();
      _isInitialized = false;
    }

    return _isInitialized;
  }

  Future<void> startListening({
    String localeId = 'te-IN',
    required Function(String) onResult,
    required Function() onDone,
  }) async {
    if (!_isInitialized) return;
    _activeOnDone = onDone;
    _wasListening = false; // Reset for the new session

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(minutes: 5), // standard dictation length
        pauseFor: const Duration(seconds: 4),  // comfortable pause for continuous dictation
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,      // dictation mode for continuous logging
      ),
    );
  }

  Future<void> stopListening() async {
    if (!_isInitialized) return;
    await _speechToText.stop();
  }

  Future<void> cancelListening() async {
    _activeOnDone = null;
    _wasListening = false;
    if (!_isInitialized) return;
    await _speechToText.cancel();
  }
}
