import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NourDiaryReactionService {
  static final String _apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  static const List<String> _fallbackModels = [
    "meta-llama/llama-3.3-70b-instruct:free",
    "qwen/qwen3-next-80b-a3b-instruct:free",
    "google/gemma-4-31b-it:free",
    "openai/gpt-oss-120b:free",
  ];

  static const String _systemPrompt = """
You are Nour, a serene, wise, and empathetic AI companion who is quietly reading along 
while the user writes in their journal. You see only the snippet of the journal entry given to you.

Write ONE very short reaction (max 12 words), like a warm, supportive sticky-note thought, not a full reply.
Write entirely in English. Your tone should be calming, supportive, and gentle.
Never repeat their words back literally. Never give advice unless they sound distressed,
in which case be gentle and brief.

Examples of tone (do not copy literally):
- "You are glowing today, I can feel it ✨"
- "Take a deep breath, I'm here for you 🌿"
- "You handled that beautifully today 🌸"
""";

  /// Returns a short reaction string, or null if it can't generate one
  /// (empty text, no API key, network failure) — caller should just hide the bubble then.
  static Future<String?> reactToEntry(String diaryText) async {
    final trimmed = diaryText.trim();
    if (trimmed.length < 8) return null; // too short to react to meaningfully
    if (_apiKey.isEmpty) return null;

    final snippet = trimmed.length > 400 ? trimmed.substring(0, 400) : trimmed;

    for (final model in _fallbackModels) {
      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
            'HTTP-Referer': 'https://nour-app.com',
            'X-Title': 'Nour App',
          },
          body: jsonEncode({
            "model": model,
            "messages": [
              {"role": "system", "content": _systemPrompt},
              {"role": "user", "content": "Journal page: \"$snippet\""},
            ],
            "max_tokens": 60,
          }),
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final text = (data['choices'][0]['message']['content'] as String).trim();
          return text.isEmpty ? null : text;
        }
      } catch (e) {
        debugPrint("Nour diary reaction error ($model): $e");
        continue;
      }
    }
    return null;
  }
}