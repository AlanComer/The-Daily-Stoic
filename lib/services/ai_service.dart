import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AiService {
  static const _prompt =
      'In one short sentence, summarize the key insight of the following Stoic passage:\n\n';

  /// Generates a one-line summary for [body] using the given [provider].
  ///
  /// [provider] must be 'openai', 'anthropic', or 'ollama'.
  /// [apiKey] is ignored for Ollama — pass an empty string.
  ///
  /// Throws a descriptive [Exception] on HTTP errors or connection failure.
  static Future<String> generateSummary({
    required String body,
    required String provider,
    required String apiKey,
  }) async {
    final prompt = _prompt + body;

    switch (provider) {
      case 'openai':
        return _callOpenAi(prompt, apiKey);
      case 'anthropic':
        return _callAnthropic(prompt, apiKey);
      case 'ollama':
        return _callOllama(prompt);
      default:
        throw Exception('Unknown AI provider: $provider');
    }
  }

  // ---------------------------------------------------------------------------
  // OpenAI
  // ---------------------------------------------------------------------------

  static Future<String> _callOpenAi(String prompt, String apiKey) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'model': 'gpt-4o-mini',
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('OpenAI error ${response.statusCode}: check your API key in Settings.');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return (data['choices'] as List).first['message']['content'] as String;
    } on TimeoutException {
      throw Exception('OpenAI request timed out. Check your internet connection.');
    }
  }

  // ---------------------------------------------------------------------------
  // Anthropic
  // ---------------------------------------------------------------------------

  static Future<String> _callAnthropic(String prompt, String apiKey) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'model': 'claude-haiku-4-5-20251001',
              'max_tokens': 150,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Anthropic error ${response.statusCode}: check your API key in Settings.');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return (data['content'] as List).first['text'] as String;
    } on TimeoutException {
      throw Exception('Anthropic request timed out. Check your internet connection.');
    }
  }

  // ---------------------------------------------------------------------------
  // Ollama (local, OpenAI-compatible API)
  // ---------------------------------------------------------------------------

  static Future<String> _callOllama(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse('http://localhost:11434/v1/chat/completions'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'model': 'llama3.2',
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception('Ollama error ${response.statusCode}: ${response.body}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return (data['choices'] as List).first['message']['content'] as String;
    } on SocketException {
      throw Exception(
        "Ollama doesn't appear to be running. Start it with: ollama serve",
      );
    }
  }
}
