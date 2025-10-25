import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../application/ai_models.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(client: http.Client());
});

class AiService {
  AiService({required http.Client client}) : _client = client;

  static const _summaryModel = 'gpt-4o-mini';
  static const _transcriptionModel = 'whisper-1';

  final http.Client _client;
  String? _apiKey;

  Future<void> warmup() async {}

  void configure({required String apiKey}) {
    _apiKey = apiKey;
  }

  Future<String> transcribeAudio(String filePath) async {
    final key = _apiKey;
    if (key == null) {
      throw StateError('API key not configured');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
    )
      ..headers['Authorization'] = 'Bearer $key'
      ..fields['model'] = _transcriptionModel
      ..files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw Exception('Failed to transcribe: ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['text'] as String? ?? '';
  }

  Future<LoopMindInsights> summarise(String transcript) async {
    final key = _apiKey;
    if (key == null) {
      throw StateError('API key not configured');
    }
    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _summaryModel,
        'messages': [
          {
            'role': 'system',
            'content': 'You are LoopMind, an idea companion. ' 'Summarise the idea in one sentence and craft three reflective prompts.'
          },
          {
            'role': 'user',
            'content': transcript,
          }
        ],
        'temperature': 0.7,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to generate summary: ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (body['choices'] as List<dynamic>).first['message']['content']
        as String;
    return LoopMindInsights.fromCombinedText(content);
  }
}
