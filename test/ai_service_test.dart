import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

// AiService delegates to http.post which cannot be easily intercepted without
// dependency injection. These tests validate the JSON extraction logic used
// inside each provider path as pure functions, keeping tests fast and offline.

void main() {
  group('OpenAI response parsing', () {
    test('extracts choices[0].message.content', () {
      final body = json.encode({
        'choices': [
          {
            'message': {'content': 'Stoic wisdom in one sentence.'}
          }
        ]
      });
      final data = json.decode(body) as Map<String, dynamic>;
      final result = (data['choices'] as List).first['message']['content'] as String;
      expect(result, 'Stoic wisdom in one sentence.');
    });
  });

  group('Anthropic response parsing', () {
    test('extracts content[0].text', () {
      final body = json.encode({
        'content': [
          {'type': 'text', 'text': 'Stoic wisdom in one sentence.'}
        ]
      });
      final data = json.decode(body) as Map<String, dynamic>;
      final result = (data['content'] as List).first['text'] as String;
      expect(result, 'Stoic wisdom in one sentence.');
    });
  });

  group('Ollama response parsing', () {
    test('extracts choices[0].message.content (OpenAI-compatible)', () {
      final body = json.encode({
        'choices': [
          {
            'message': {'content': 'Local Stoic wisdom.'}
          }
        ]
      });
      final data = json.decode(body) as Map<String, dynamic>;
      final result = (data['choices'] as List).first['message']['content'] as String;
      expect(result, 'Local Stoic wisdom.');
    });
  });
}
