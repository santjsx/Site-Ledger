import 'dart:convert';
import 'package:http/http.dart' as http;
import 'speech_handler.dart';

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<ParsedEntry> parseTranscript(
    String transcript,
    List<String> apiKeys,
    String model, {
    http.Client? client,
  }) async {
    final activeKeys = apiKeys.where((k) => k.trim().isNotEmpty).toList();
    if (activeKeys.isEmpty) {
      throw Exception('No valid Groq API Keys provided');
    }

    final systemPrompt = '''
You are a professional Site Ledger Parser for a construction or site management app. Your task is to analyze the voice transcript (which may be in English, Telugu, or a mixture of both) and extract structured ledger values.

You MUST respond ONLY with a JSON object containing exactly these keys:
- "labourCount": integer or null (total count of workers/labourers/people mentioned. If male and female splits are mentioned, this should be the sum of them.)
- "labourPaid": double or null (total money paid to labourers/workers. If male and female splits are mentioned, this should be the sum of them.)
- "ownerAmount": double or null (money received from or paid by the owner)
- "magaLabourCount": integer or null (count of male workers/maga coolie/మగ కూలీలు/మగవాళ్ళు mentioned)
- "magaLabourPaid": double or null (money paid specifically to male workers/maga coolie)
- "aadaLabourCount": integer or null (count of female workers/aada coolie/ఆడ కూలీలు/ఆడవాళ్ళు mentioned)
- "aadaLabourPaid": double or null (money paid specifically to female workers/aada coolie)
- "note": string or null (notes, descriptions of material, work details, or general text. If the user states a general note/description that doesn't fit other fields, map it to "note". Do not include keywords like 'note:' or 'గమనిక:' in the note text itself. Clean up the note text.)
- "cleanedTranscript": string (a corrected, clean version of the transcript in the original language. Correct all voice input repetitions, glitches, stuttering, and overlapping phrases, while keeping all semantic details, amounts, and numbers intact. Do not add any new facts. Format it as a natural, well-structured sentence.)

Here are example Telugu and English inputs and their expected outputs:
Input: "కూలీలు ఐదుగురు జీతాలు ఐదు వేలు ఓనర్ ఖర్చు రెండు వేల ఐదు వందలు"
Output: {"labourCount": 5, "labourPaid": 5000.0, "ownerAmount": 2500.0, "magaLabourCount": null, "magaLabourPaid": null, "aadaLabourCount": null, "aadaLabourPaid": null, "note": null, "cleanedTranscript": "ఈరోజు ఐదుగురు కూలీల జీతాలు 5000 మరియు ఓనర్ ఖర్చు 2500."}

Input: "మగ కూలీలు ఐదుగురు వాళ్లకి ఐదు వేలు ఇచ్చాము ఆడ కూలీలు నలుగురు వాళ్లకి మూడు వేలు ఇచ్చాము"
Output: {"labourCount": 9, "labourPaid": 8000.0, "ownerAmount": null, "magaLabourCount": 5, "magaLabourPaid": 5000.0, "aadaLabourCount": 4, "aadaLabourPaid": 3000.0, "note": null, "cleanedTranscript": "మగ కూలీలు ఐదుగురికి 5000 మరియు ఆడ కూలీలు నలుగురికి 3000 ఇచ్చాము."}

Input: "మగవాళ్లు ముగ్గురు ఆడవాళ్లు ఇద్దరు వచ్చారు ఓనర్ ఖర్చు పదివేలు"
Output: {"labourCount": 5, "labourPaid": null, "ownerAmount": 10000.0, "magaLabourCount": 3, "magaLabourPaid": null, "aadaLabourCount": 2, "aadaLabourPaid": null, "note": null, "cleanedTranscript": "మగవాళ్లు ముగ్గురు మరియు ఆడవాళ్లు ఇద్దరు వచ్చారు, ఓనర్ 10000 ఇచ్చారు."}

Input: "లేబర్ ముగ్గురికి 1500 ఇచ్చాము ఓనర్ ఖర్చు వెయ్యి నోట్ సిమెంట్"
Output: {"labourCount": 3, "labourPaid": 1500.0, "ownerAmount": 1000.0, "magaLabourCount": null, "magaLabourPaid": null, "aadaLabourCount": null, "aadaLabourPaid": null, "note": "సిమెంట్", "cleanedTranscript": "ముగ్గురు లేబర్లకు 1500 ఇచ్చాము, ఓనర్ ఖర్చు 1000 మరియు సిమెంట్ నోట్ చేసాము."}

Input: "ఈరోజు ఇసుక వచ్చింది"
Output: {"labourCount": null, "labourPaid": null, "ownerAmount": null, "magaLabourCount": null, "magaLabourPaid": null, "aadaLabourCount": null, "aadaLabourPaid": null, "note": "ఈరోజు ఇసుక వచ్చింది", "cleanedTranscript": "ఈరోజు ఇసుక వచ్చింది."}

Input: "5 workers, paid 5000, owner spent 1500, note tiles"
Output: {"labourCount": 5, "labourPaid": 5000.0, "ownerAmount": 1500.0, "magaLabourCount": null, "magaLabourPaid": null, "aadaLabourCount": null, "aadaLabourPaid": null, "note": "tiles", "cleanedTranscript": "5 workers paid 5000, owner spent 1500, note tiles."}

Input: "owner gave 5000 rupees and labor paid is 2000"
Output: {"labourCount": null, "labourPaid": 2000.0, "ownerAmount": 5000.0, "magaLabourCount": null, "magaLabourPaid": null, "aadaLabourCount": null, "aadaLabourPaid": null, "note": null, "cleanedTranscript": "Owner gave 5000 rupees and labor paid is 2000."}

Input: "ఈరోజు కూలీలు 5 మంది లీలు 3000 3000 ఓనర్ ఇచ్చింది ఈ పదివేలు ఓనర్ ఇచ్చింది 10000"
Output: {"labourCount": 5, "labourPaid": 3000.0, "ownerAmount": 10000.0, "magaLabourCount": null, "magaLabourPaid": null, "aadaLabourCount": null, "aadaLabourPaid": null, "note": null, "cleanedTranscript": "ఈరోజు 5 మంది కూలీలకు 3000 ఇచ్చాము, మరియు ఓనర్ 10000 ఇచ్చారు."}

Make sure to convert Telugu spoken numbers to digits (e.g. "ముగ్గురికి" -> 3, "ఐదు వేలు" -> 5000, "వెయ్యి" -> 1000).
Strictly output ONLY a valid JSON object. Do not include any explanation, markdown blocks, or other text outside the JSON.
''';

    final body = json.encode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': 'Transcript: "$transcript"'}
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.0,
    });

    List<String> errors = [];

    for (int i = 0; i < activeKeys.length; i++) {
      final apiKey = activeKeys[i];
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

      final httpClient = client ?? http.Client();
      try {
        final response = await httpClient
            .post(
              Uri.parse(_baseUrl),
              headers: headers,
              body: body,
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          final choices = decoded['choices'] as List?;
          if (choices == null || choices.isEmpty) {
            throw Exception('No parsing choices returned from Groq API');
          }

          final content = choices[0]['message']?['content'] as String?;
          if (content == null || content.isEmpty) {
            throw Exception('Empty content returned from Groq API');
          }

          final parsedJson = json.decode(content) as Map<String, dynamic>;

          return ParsedEntry(
            labourCount: _parseInt(parsedJson['labourCount']),
            labourPaid: _parseDouble(parsedJson['labourPaid']),
            ownerAmount: _parseDouble(parsedJson['ownerAmount']),
            note: parsedJson['note']?.toString().trim(),
            cleanedTranscript: parsedJson['cleanedTranscript']?.toString().trim(),
            magaLabourCount: _parseInt(parsedJson['magaLabourCount']),
            magaLabourPaid: _parseDouble(parsedJson['magaLabourPaid']),
            aadaLabourCount: _parseInt(parsedJson['aadaLabourCount']),
            aadaLabourPaid: _parseDouble(parsedJson['aadaLabourPaid']),
          );
        } else {
          final errorMsg = _tryParseErrorMessage(response.body);
          errors.add('Key #${i + 1} failed (${response.statusCode}): $errorMsg');
        }
      } catch (e) {
        errors.add('Key #${i + 1} error: $e');
      } finally {
        if (client == null) {
          httpClient.close();
        }
      }
    }

    throw Exception('All Groq API Keys failed:\n${errors.join('\n')}');
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString());
  }

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString());
  }

  static String _tryParseErrorMessage(String body) {
    try {
      final decoded = json.decode(body);
      return decoded['error']?['message']?.toString() ?? 'Unknown API Error';
    } catch (_) {
      return 'Failed to parse response body';
    }
  }
}
