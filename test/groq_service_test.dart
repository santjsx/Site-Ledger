import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:site_voice_ledger/groq_service.dart';

void main() {
  test('GroqService parseTranscript success parses variables correctly', () async {
    final mockResponse = {
      'choices': [
        {
          'message': {
            'content': json.encode({
              'labourCount': 5,
              'labourPaid': 5000.0,
              'ownerAmount': 1000.0,
              'note': 'tiles purchased'
            })
          }
        }
      ]
    };

    final client = MockClient((request) async {
      return http.Response(json.encode(mockResponse), 200);
    });

    final entry = await GroqService.parseTranscript(
      'some transcript text',
      ['gsk_test_key'],
      'llama-3.3-70b-versatile',
      client: client,
    );

    expect(entry.labourCount, 5);
    expect(entry.labourPaid, 5000.0);
    expect(entry.ownerAmount, 1000.0);
    expect(entry.note, 'tiles purchased');
  });

  test('GroqService parseTranscript handles nulls and strings gracefully', () async {
    final mockResponse = {
      'choices': [
        {
          'message': {
            'content': json.encode({
              'labourCount': '10',
              'labourPaid': '2500.50',
              'ownerAmount': null,
              'note': '  cement  '
            })
          }
        }
      ]
    };

    final client = MockClient((request) async {
      return http.Response(json.encode(mockResponse), 200);
    });

    final entry = await GroqService.parseTranscript(
      'another transcript text',
      ['gsk_test_key'],
      'llama-3.3-70b-versatile',
      client: client,
    );

    expect(entry.labourCount, 10);
    expect(entry.labourPaid, 2500.50);
    expect(entry.ownerAmount, null);
    expect(entry.note, 'cement');
  });

  test('GroqService parseTranscript throws exception on API error response', () async {
    final mockError = {
      'error': {
        'message': 'Invalid API Key'
      }
    };

    final client = MockClient((request) async {
      return http.Response(json.encode(mockError), 401);
    });

    expect(
      () => GroqService.parseTranscript(
        'text',
        ['wrong_key'],
        'llama-3.3-70b-versatile',
        client: client,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('GroqService rotates keys when first key fails and second key succeeds', () async {
    final mockSuccessResponse = {
      'choices': [
        {
          'message': {
            'content': json.encode({
              'labourCount': 3,
              'labourPaid': 3000.0,
              'ownerAmount': null,
              'note': 'paint'
            })
          }
        }
      ]
    };

    int requestCount = 0;

    final client = MockClient((request) async {
      requestCount++;
      if (requestCount == 1) {
        // First request is with key #1, return 429 Rate Limit
        return http.Response('{"error": {"message": "Rate Limit Exceeded"}}', 429);
      } else {
        // Second request with key #2 succeeds
        return http.Response(json.encode(mockSuccessResponse), 200);
      }
    });

    final entry = await GroqService.parseTranscript(
      'some transcript text',
      ['gsk_bad_key', 'gsk_good_key'],
      'llama-3.3-70b-versatile',
      client: client,
    );

    expect(requestCount, 2); // Verify that it made two requests
    expect(entry.labourCount, 3);
    expect(entry.labourPaid, 3000.0);
    expect(entry.note, 'paint');
  });
}
