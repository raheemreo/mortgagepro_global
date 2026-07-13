// lib/services/ai_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AIChatMessage {
  final String text;
  final bool isUser;

  AIChatMessage({required this.text, required this.isUser});
}

class AIService {
  static final AIService instance = AIService._internal();
  AIService._internal();

  // All Gemini API Keys in order of fallback execution.
  // Inject at build time: --dart-define=GEMINI_API_KEY=your_key
  // Never hardcode keys here — GitHub secret scanning will block the push.
  final List<String> _geminiKeys = [
    const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
    const String.fromEnvironment('GEMINI_API_KEY_1', defaultValue: ''),
    const String.fromEnvironment('GEMINI_API_KEY_2', defaultValue: ''),
    const String.fromEnvironment('GEMINI_API_KEY_3', defaultValue: ''),
    const String.fromEnvironment('GEMINI_API_KEY_4', defaultValue: ''),
    const String.fromEnvironment('GEMINI_API_KEY_5', defaultValue: ''),
    const String.fromEnvironment('GEMINI_API_KEY_6', defaultValue: ''),
    const String.fromEnvironment('GEMINI_API_KEY_7', defaultValue: ''),
  ];

  // Groq API Key — inject via --dart-define=GROQ_API_KEY=your_key
  final String _groqKey = const String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

  // Shared Dio client to optimize networking performance (reusing connections)
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  // Country-specific Gemini keys as defined by environment
  String _getCountrySpecificKey(String countryCode) {
    switch (countryCode.toLowerCase()) {
      case 'usa':
        return const String.fromEnvironment('GEMINI_API_KEY_USA', defaultValue: '');
      case 'uk':
        return const String.fromEnvironment('GEMINI_API_KEY_UK', defaultValue: '');
      case 'au':
        return const String.fromEnvironment('GEMINI_API_KEY_AU', defaultValue: '');
      case 'ca':
        return const String.fromEnvironment('GEMINI_API_KEY_CA', defaultValue: '');
      case 'in':
        return const String.fromEnvironment('GEMINI_API_KEY_IN', defaultValue: '');
      case 'nz':
        return const String.fromEnvironment('GEMINI_API_KEY_NZ', defaultValue: '');
      case 'eu':
        return const String.fromEnvironment('GEMINI_API_KEY_EU', defaultValue: '');
      default:
        return '';
    }
  }

  /// Sends a request to the AI models with fallback keys.
  /// If [customUserKey] is provided and is not empty, it will only use that key and throw errors on failure (so the user gets feedback on their key).
  /// If [customUserKey] is empty, it tries [countryCode]-specific key, then falls back to [_geminiKeys] one-by-one, and finally to [_groqKey].
  Future<String> sendMessage({
    required String question,
    required String systemInstruction,
    required List<AIChatMessage> history,
    required String countryCode,
  }) async {
    // 1. Clean history to ensure it starts with a user turn, alternates strictly, and ends with a model turn
    final List<AIChatMessage> cleanedHistory = [];
    bool expectingUser = true;
    for (var msg in history) {
      if (msg.isUser == expectingUser) {
        cleanedHistory.add(msg);
        expectingUser = !expectingUser;
      }
    }
    // Remove last message if it's a user message, so history ends with a model response
    if (cleanedHistory.isNotEmpty && cleanedHistory.last.isUser) {
      cleanedHistory.removeLast();
    }

    // 2. Build candidate list of Gemini Keys to try
    final List<String> candidateKeys = [];
    
    // Add country-specific key first if defined
    final countryKey = _getCountrySpecificKey(countryCode);
    if (countryKey.isNotEmpty) {
      candidateKeys.add(countryKey);
    }
    
    // Add other fallback keys, ensuring no duplicates
    for (final key in _geminiKeys) {
      if (key.isNotEmpty && !candidateKeys.contains(key)) {
        candidateKeys.add(key);
      }
    }

    // 3. Try each Gemini API key sequentially
    dynamic geminiError;
    for (int i = 0; i < candidateKeys.length; i++) {
      final apiKey = candidateKeys[i];
      try {
        debugPrint('AIService: Trying Gemini key index $i');
        final response = await _callGemini(question, systemInstruction, cleanedHistory, apiKey);
        if (response.isNotEmpty) {
          return response;
        }
      } catch (e) {
        geminiError = e;
        debugPrint('AIService: Gemini key index $i failed: $e');
      }
    }

    // 4. Fallback to Groq API using Llama model
    if (_groqKey.isNotEmpty) {
      try {
        debugPrint('AIService: Falling back to Groq Llama model');
        final response = await _callGroq(question, systemInstruction, cleanedHistory, _groqKey);
        if (response.isNotEmpty) {
          return response;
        }
      } catch (e) {
        debugPrint('AIService: Groq failed: $e');
      }
    }

    // If everything failed, throw or return empty
    throw geminiError ?? 'All AI API keys and fallbacks failed to respond.';
  }

  Future<String> _callGemini(
    String question,
    String systemInstruction,
    List<AIChatMessage> history,
    String apiKey,
  ) async {
    const model = 'gemini-2.0-flash';
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final List<Map<String, dynamic>> contents = [];
    for (var msg in history) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text}
        ]
      });
    }

    // Ensure the new question is included in contents
    contents.add({
      'role': 'user',
      'parts': [
        {'text': question}
      ]
    });

    final response = await _dio.post(
      url,
      data: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemInstruction}
          ],
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
          {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
          {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          return (parts[0]['text'] as String? ?? '').trim();
        }
      }
    }
    throw 'Invalid Gemini response structure';
  }

  Future<String> _callGroq(
    String question,
    String systemInstruction,
    List<AIChatMessage> history,
    String apiKey,
  ) async {
    const model = 'llama-3.3-70b-versatile';
    const url = 'https://api.groq.com/openai/v1/chat/completions';

    final List<Map<String, dynamic>> messages = [];
    messages.add({
      'role': 'system',
      'content': systemInstruction,
    });
    for (var msg in history) {
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }
    messages.add({
      'role': 'user',
      'content': question,
    });

    final response = await _dio.post(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
      data: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          return content.trim();
        }
      }
    }
    throw 'Invalid Groq response structure';
  }
}
