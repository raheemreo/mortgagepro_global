// lib/services/ai_service.dart
//
// Keys are loaded at runtime from secrets.json (bundled as a Flutter asset,
// gitignored). Do NOT use String.fromEnvironment for keys — those require
// --dart-define at build time and default to empty strings.
// Do NOT use user-provided custom keys — only app-supplied keys are used.

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class AIChatMessage {
  final String text;
  final bool isUser;

  AIChatMessage({required this.text, required this.isUser});
}

class AIService {
  static final AIService instance = AIService._internal();
  AIService._internal();

  // ── Runtime-loaded key pool ────────────────────────────────────────────────
  // Populated by loadKeys() at app startup from secrets.json.
  // Never hardcode values here — GitHub secret scanning blocks the push.
  final List<String> _geminiKeys = [];
  String _groqKey = '';
  bool _keysLoaded = false;

  // ── Dio client (shared, reuses connections) ────────────────────────────────
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  // ── Key loading ────────────────────────────────────────────────────────────

  /// Loads API keys from the bundled secrets.json asset.
  /// Call this once at app startup (main.dart) before any AI requests.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> loadKeysFromAssets() async {
    if (_keysLoaded) return;
    try {
      final raw = await rootBundle.loadString('secrets.json');
      final Map<String, dynamic> secrets = json.decode(raw) as Map<String, dynamic>;
      loadKeys(secrets);
    } catch (e) {
      debugPrint('AIService: Failed to load secrets.json — $e');
    }
  }

  /// Populates the key pool from a map (e.g. decoded secrets.json).
  /// Keys are tried in insertion order; empty strings are skipped.
  void loadKeys(Map<String, dynamic> secrets) {
    if (_keysLoaded) return;

    _geminiKeys.clear();
    for (var i = 0; i < 8; i++) {
      final key = i == 0
          ? secrets['GEMINI_API_KEY']
          : secrets['GEMINI_API_KEY_$i'];
      final v = (key as String? ?? '').trim();
      if (v.isNotEmpty) _geminiKeys.add(v);
    }

    _groqKey = (secrets['GROQ_API_KEY'] as String? ?? '').trim();
    _keysLoaded = true;

    debugPrint('AIService: Loaded ${_geminiKeys.length} Gemini key(s)'
        '${_groqKey.isNotEmpty ? " + Groq" : ""}');
  }

  // ── Public sendMessage ─────────────────────────────────────────────────────

  /// Sends a message through the AI fallback chain:
  ///   Gemini keys (pool, in order) → Groq Llama → throws if all fail.
  ///
  /// [question]          The user's current message.
  /// [systemInstruction] The screen-specific system prompt (with live data).
  /// [history]           Prior turns (alternating user/model, oldest first).
  /// [countryCode]       e.g. 'usa', 'uk', 'au' — for logging only.
  Future<String> sendMessage({
    required String question,
    required String systemInstruction,
    required List<AIChatMessage> history,
    required String countryCode,
  }) async {
    // Ensure keys are loaded (defensive — normally done at startup)
    if (!_keysLoaded) await loadKeysFromAssets();

    // Clean history: must alternate user/model and end with a model turn
    final List<AIChatMessage> cleanedHistory = [];
    bool expectingUser = true;
    for (final msg in history) {
      if (msg.isUser == expectingUser) {
        cleanedHistory.add(msg);
        expectingUser = !expectingUser;
      }
    }
    if (cleanedHistory.isNotEmpty && cleanedHistory.last.isUser) {
      cleanedHistory.removeLast();
    }

    // Try each Gemini key in order
    dynamic lastError;
    for (int i = 0; i < _geminiKeys.length; i++) {
      try {
        debugPrint('AIService[$countryCode]: Trying Gemini key $i');
        final response = await _callGemini(
          question, systemInstruction, cleanedHistory, _geminiKeys[i],
        );
        if (response.isNotEmpty) return response;
      } catch (e) {
        lastError = e;
        debugPrint('AIService[$countryCode]: Gemini key $i failed — $e');
      }
    }

    // Fallback: Groq Llama
    if (_groqKey.isNotEmpty) {
      try {
        debugPrint('AIService[$countryCode]: Falling back to Groq');
        final response = await _callGroq(
          question, systemInstruction, cleanedHistory, _groqKey,
        );
        if (response.isNotEmpty) return response;
      } catch (e) {
        debugPrint('AIService[$countryCode]: Groq failed — $e');
      }
    }

    throw lastError ?? Exception('All AI keys exhausted for $countryCode');
  }

  // ── Gemini ────────────────────────────────────────────────────────────────

  Future<String> _callGemini(
    String question,
    String systemInstruction,
    List<AIChatMessage> history,
    String apiKey,
  ) async {
    const model = 'gemini-2.0-flash';
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final contents = <Map<String, dynamic>>[];
    for (final msg in history) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text}
        ],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [
        {'text': question}
      ],
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
    throw Exception('Invalid Gemini response — status ${response.statusCode}');
  }

  // ── Groq ──────────────────────────────────────────────────────────────────

  Future<String> _callGroq(
    String question,
    String systemInstruction,
    List<AIChatMessage> history,
    String apiKey,
  ) async {
    const model = 'llama-3.3-70b-versatile';
    const url = 'https://api.groq.com/openai/v1/chat/completions';

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemInstruction},
    ];
    for (final msg in history) {
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }
    messages.add({'role': 'user', 'content': question});

    final response = await _dio.post(
      url,
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      }),
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
        if (content != null && content.isNotEmpty) return content.trim();
      }
    }
    throw Exception('Invalid Groq response — status ${response.statusCode}');
  }
}
