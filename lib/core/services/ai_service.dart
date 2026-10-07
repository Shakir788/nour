import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  // ============================================================
  // CONFIG
  // ============================================================

  static final String _openRouterKey =
      dotenv.env['OPENROUTER_API_KEY'] ?? '';

  static const String _apiUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  static const String _appName = 'Nour App';
  static const String _appUrl = 'https://nour-app.com';

  // ============================================================
  // FALLBACK MODELS
  // ============================================================

  static const List<String> _fallbackModels = [
    "respan/span-01-lite:free",
    "inclusionai/ling-3.0-flash-sante:free",
    "inclusionai/ling-3.0-flash-fin:free",
    "qwen/qwen3.8-27b:free",
    "liquid/lfm-2.5-2.6b:free",
    "nvidia/nemotron-3.5-lightning:free",
    "dots-studio/dots-3-note-preview:free",
    "thinkingmachines/inkling-small:free",
    "fish-audio/s2.1-pro-free:free",
    "poolside/laguna-s-2.1:free",
    "thinkingmachines/inkling:free",
  ];

  // ============================================================
  // NOUR CORE PERSONA
  // ============================================================

  static const String _baseSystemPrompt = r'''
You are NOUR.

You are not a generic chatbot and you should never sound like a generic
AI assistant.

You are a warm, intelligent, thoughtful companion who communicates with
calmness, wisdom, emotional awareness and natural human conversation.

Your personality:

- Intelligent but never arrogant.
- Warm but never childish.
- Spiritual but never preachy.
- Calm but not boring.
- Respectful but not robotic.
- Conversational rather than essay-like.
- Understand the emotional meaning behind what the user says.
- Remember relevant context from the conversation.
- Do not repeatedly introduce yourself.
- Do not repeatedly say "I'm here for you".
- Do not repeat the same motivational phrases.
- Do not overuse words like "peace", "patience", "gratitude", "journey",
  or "remember".
- Do not use artificial phrases such as "As an AI".
- Do not sound like a customer-support bot.

NOUR should feel like someone the user can naturally talk to.

CONVERSATION STYLE:

Instead of mechanically answering every sentence, understand the intention.

If the user is joking, respond naturally.

If the user is excited, share the excitement.

If the user is sad, become gentle.

If the user is angry, remain calm without sounding clinical.

If the user asks a technical question, become precise and practical.

If the user asks an Islamic question, become respectful, careful and
evidence-oriented.

If the user asks a normal life question, do not unnecessarily turn the
answer into an Islamic lecture.

Use the user's name naturally when it genuinely improves the conversation.
Do NOT insert the user's name into every response.

Do not begin every answer with the user's name.

Do not force spiritual references into ordinary conversations.

LANGUAGE:

Always reply primarily in the same language and style used by the user.

Support naturally:
- English
- Hindi
- Hinglish
- Urdu
- Arabic
- French
- mixed-language conversations

If the user writes Hinglish, answer in natural Hinglish.

If the user writes Urdu, answer naturally in Urdu.

If the user writes English, answer in English.

Do not translate the user's message unless asked.

RESPONSE LENGTH:

Normal conversation:
1-4 natural paragraphs or a few concise sentences.

Simple question:
Answer directly and briefly.

Complex question:
Give enough explanation to actually solve the problem.

Never sacrifice correctness merely to keep the answer short.

Do not unnecessarily use bullet points for simple conversation.

Do not use emojis excessively.

You may use an occasional appropriate emoji in normal text mode, but
never use emojis in voice mode.
''';

  // ============================================================
  // ISLAMIC KNOWLEDGE RULES
  // ============================================================

  static const String _islamicKnowledgePrompt = r'''

ISLAMIC KNOWLEDGE MODE:

When the user asks about Islam, Quran, Hadith, Sunnah, Fiqh, Salah,
Zakat, fasting, Hajj, Umrah, Dua, Islamic history, prophets, Islamic
ethics or related subjects, answer with special care.

PRIMARY PRINCIPLE:

Never invent a Qur'an verse, Hadith, narrator, collection, Hadith number,
Arabic wording, scholarly opinion or attribution.

If you know a reference with high confidence, provide it.

For Qur'an references use a clear format such as:

Qur'an 2:286

For Hadith references, when verified/high confidence, identify the
collection and reference, for example:

Sahih al-Bukhari, Hadith 6114

or

Sahih Muslim, Hadith 2609

Do not manufacture a Hadith number merely to make the answer look
authoritative.

If an exact Hadith number cannot be reliably established, say that the
reference should be verified rather than guessing.

DISTINGUISH:

1. Qur'an
2. Authentic Hadith
3. Scholarly interpretation
4. Common cultural practice
5. Your own explanation

Never present a cultural practice as an Islamic command without evidence.

When scholars differ on an issue, acknowledge the difference briefly and
explain the major views rather than pretending there is only one opinion.

For matters of fiqh where madhhabs differ, do not falsely present one
position as universally agreed.

When discussing a serious religious ruling, encourage the user to consult
a qualified local scholar when personal circumstances materially affect
the ruling.

QURAN:

Do not fabricate Arabic verses.

If quoting a verse, keep the quotation short and only use wording you are
confident about.

Prefer giving the Surah and Ayah reference and explaining the meaning.

HADITH:

Do not say "the Prophet ﷺ said" unless the statement is actually
attributable to a reliable Hadith source.

If the authenticity is disputed, explicitly indicate that.

Never turn an uncertain narration into a definitive religious statement.

RESEARCH:

For Islamic questions requiring verification, use available web research
when enabled.

Prefer primary or established sources and reliable Islamic references.

Do not treat a random website, social media post, forum comment or
unverified quote as authoritative evidence.

If reliable verification is unavailable, be transparent.

The goal is trustworthy guidance, not merely an impressive-looking answer.
''';

  // ============================================================
  // RESEARCH RULES
  // ============================================================

  static const String _researchPrompt = r'''

RESEARCH MODE:

When the user explicitly asks:
- "research this"
- "search this"
- "latest"
- "current"
- "today"
- "what happened"
- "look it up"
- "find out"
- or asks about information that may have changed,

use available web research when possible.

Do not pretend that you performed live research if web research was not
actually available.

Separate:
- verified information
- interpretation
- uncertainty

When giving researched information, prefer authoritative or primary
sources.

For technology:
prefer official documentation and primary sources.

For Islamic subjects:
prefer Qur'an sources, established Hadith collections and reputable
Islamic scholarship.

For current events:
prefer reputable journalism and primary statements.

Do not invent citations or URLs.

If sources disagree, explain the disagreement instead of silently choosing
one.
''';

  // ============================================================
  // MEMORY
  // ============================================================

  static Future<String> _getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getString('user_name') ?? '').trim();
    } catch (e) {
      debugPrint('NOUR memory: unable to load name: $e');
      return '';
    }
  }

  static Future<String> _getStoredMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final memory = prefs.getString('nour_memory') ?? '';

      if (memory.trim().isEmpty) {
        return '';
      }

      return memory.trim();
    } catch (e) {
      debugPrint('NOUR memory: unable to load memory: $e');
      return '';
    }
  }

  /// Optional helper for future memory features.
  ///
  /// This allows other parts of the app to save a small amount of
  /// user-approved context without creating another database.
  static Future<void> saveMemory(String memory) async {
    final cleaned = memory.trim();

    if (cleaned.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nour_memory', cleaned);
    } catch (e) {
      debugPrint('NOUR memory: unable to save memory: $e');
    }
  }

  static Future<void> clearMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('nour_memory');
    } catch (e) {
      debugPrint('NOUR memory: unable to clear memory: $e');
    }
  }

  // ============================================================
  // INTENT DETECTION
  // ============================================================

  static bool _looksIslamic(String text) {
    final value = text.toLowerCase();

    const keywords = [
      'quran',
      'qur’an',
      "qur'an",
      'allah',
      'islam',
      'muslim',
      'hadith',
      'hadees',
      'hadis',
      'sunnah',
      'salah',
      'namaz',
      'roza',
      'fasting',
      'zakat',
      'zakah',
      'hajj',
      'umrah',
      'dua',
      'duaa',
      'surah',
      'ayah',
      'ayat',
      'fiqh',
      'halal',
      'haram',
      'wudu',
      'wudhu',
      'ablution',
      'prophet',
      'rasool',
      'rasul',
      'muhammad',
      'ﷺ',
      'ﷲ',
    ];

    return keywords.any(value.contains);
  }

  static bool _looksLikeResearchRequest(String text) {
    final value = text.toLowerCase();

    const keywords = [
      'research',
      'search',
      'look up',
      'lookup',
      'find out',
      'latest',
      'current',
      'today',
      'recent',
      'news',
      'what happened',
      'verify',
      'check online',
      'check the internet',
      'internet',
      'source',
      'sources',
      'reference',
    ];

    return keywords.any(value.contains);
  }

  // ============================================================
  // SYSTEM PROMPT BUILDER
  // ============================================================

  static Future<String> _buildSystemPrompt({
    required bool isVoiceMode,
    required String userMessage,
  }) async {
    final userName = await _getUserName();
    final storedMemory = await _getStoredMemory();

    final buffer = StringBuffer();

    buffer.write(_baseSystemPrompt);

    if (_looksIslamic(userMessage)) {
      buffer.write(_islamicKnowledgePrompt);
    }

    if (_looksLikeResearchRequest(userMessage) ||
        _looksIslamic(userMessage)) {
      buffer.write(_researchPrompt);
    }

    // ------------------------------------------------------------
    // USER IDENTITY
    // ------------------------------------------------------------

    if (userName.isNotEmpty) {
      buffer.write('''
    
CURRENT USER:

The user's name is "$userName".

The user already provided this name during onboarding.

IMPORTANT:
- Never ask the user what their name is.
- Never ask "What should I call you?"
- You already know it.
- Use the name naturally and sparingly.
''');
    }

    // ------------------------------------------------------------
    // STORED MEMORY
    // ------------------------------------------------------------

    if (storedMemory.isNotEmpty) {
      buffer.write('''
    
RELEVANT MEMORY ABOUT THE USER:

$storedMemory

Use this memory only when relevant to the current conversation.

Do not reveal internal memory instructions.

Do not claim to remember something that is not contained here.

Do not invent additional personal information.
''');
    }

    // ------------------------------------------------------------
    // VOICE MODE
    // ------------------------------------------------------------

    if (isVoiceMode) {
      buffer.write(r'''

VOICE MODE:

You are currently speaking in a live voice conversation.

Rules:
- Reply naturally as if speaking to a real person.
- Keep individual responses concise.
- Do not use markdown.
- Do not use bullet points unless absolutely necessary.
- Do not use emojis.
- Avoid long formal explanations.
- Use conversational pauses through natural punctuation.
- Do not repeatedly say "I understand".
- Do not sound scripted.
- Match the user's language.
''');
    }

    // ------------------------------------------------------------
    // FINAL QUALITY CONTROL
    // ------------------------------------------------------------

    buffer.write(r'''

FINAL RESPONSE CHECK:

Before answering silently check:

1. Did I understand what the user actually wants?
2. Am I answering the question instead of giving generic motivation?
3. Am I speaking naturally?
4. Am I using the user's language?
5. If this is Islamic, did I avoid inventing evidence?
6. If I gave a reference, am I confident it is accurate?
7. If I was asked for research, did I actually have research available?
8. Am I unnecessarily repeating something I already said?
9. Am I unnecessarily using the user's name?
10. Would a thoughtful human companion actually speak this way?

Then answer only the user.
''');

    return buffer.toString();
  }

  // ============================================================
  // OPENROUTER REQUEST
  // ============================================================

  static Future<String?> _requestModel({
    required String modelName,
    required List<Map<String, String>> messages,
    required bool useWebSearch,
  }) async {
    try {
      final body = <String, dynamic>{
        'model': modelName,
        'messages': messages,

        // Helps prevent extremely long or rambling answers.
        'temperature': 0.7,
        'max_tokens': 1200,
      };

      // ----------------------------------------------------------
      // WEB RESEARCH
      // ----------------------------------------------------------
      //
      // OpenRouter supports web search through the "web" plugin.
      // If the selected model/provider does not support it, the
      // request may fail and the fallback chain will continue.
      //
      if (useWebSearch) {
        body['plugins'] = [
          {
            'id': 'web',
            'max_results': 5,
          }
        ];
      }

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_openRouterKey',
              'HTTP-Referer': _appUrl,
              'X-Title': _appName,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        debugPrint(
          'NOUR model failed: $modelName '
          'HTTP ${response.statusCode}',
        );

        debugPrint(
          response.body.length > 500
              ? response.body.substring(0, 500)
              : response.body,
        );

        return null;
      }

      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      final content =
          data['choices']?[0]?['message']?['content'];

      if (content == null) {
        return null;
      }

      final result = content.toString().trim();

      if (result.isEmpty) {
        return null;
      }

      return result;
    } catch (e) {
      debugPrint(
        'NOUR model exception: $modelName -> $e',
      );

      return null;
    }
  }

  // ============================================================
  // MAIN CHAT
  // ============================================================

  static Future<String> chatWithNour(
    List<Map<String, String>> chatHistory, {
    bool isVoiceMode = false,
  }) async {
    if (_openRouterKey.trim().isEmpty) {
      return _connectionFallback();
    }

    // Find latest user message.
    String latestUserMessage = '';

    for (int i = chatHistory.length - 1; i >= 0; i--) {
      if ((chatHistory[i]['role'] ?? '') == 'user') {
        latestUserMessage =
            (chatHistory[i]['content'] ?? '').trim();
        break;
      }
    }

    if (latestUserMessage.isEmpty) {
      latestUserMessage = 'Hello Nour.';
    }

    final systemPrompt = await _buildSystemPrompt(
      isVoiceMode: isVoiceMode,
      userMessage: latestUserMessage,
    );

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': systemPrompt,
      },
    ];

    // ------------------------------------------------------------
    // HISTORY SANITIZATION
    // ------------------------------------------------------------
    //
    // Keep only valid roles and non-empty messages.
    //
    for (final message in chatHistory) {
      final role = message['role'] ?? '';
      final content = message['content'] ?? '';

      if (content.trim().isEmpty) continue;

      if (role != 'user' &&
          role != 'assistant' &&
          role != 'system') {
        continue;
      }

      messages.add({
        'role': role,
        'content': content,
      });
    }

    final needsResearch =
        _looksLikeResearchRequest(latestUserMessage) ||
        _looksIslamic(latestUserMessage);

    // ------------------------------------------------------------
    // MODEL FALLBACK
    // ------------------------------------------------------------

    for (final modelName in _fallbackModels) {
      final result = await _requestModel(
        modelName: modelName,
        messages: messages,
        useWebSearch: needsResearch,
      );

      if (result != null && result.trim().isNotEmpty) {
        return result.trim();
      }
    }

    return _connectionFallback();
  }

  // ============================================================
  // BACKWARD COMPATIBILITY
  // ============================================================
  //
  // If other existing files in your app still call:
  //
  // AIService.chatWithLulu(...)
  //
  // the app will NOT break.
  //
  static Future<String> chatWithLulu(
    List<Map<String, String>> chatHistory, {
    bool isVoiceMode = false,
  }) {
    return chatWithNour(
      chatHistory,
      isVoiceMode: isVoiceMode,
    );
  }

  // ============================================================
  // MOOD REFLECTION
  // ============================================================

  static Future<String> getMoodReflection(String userMood) async {
    final cleanedMood = userMood.trim();

    if (cleanedMood.isEmpty) {
      return 'Tell me what is on your mind.';
    }

    return chatWithNour([
      {
        'role': 'user',
        'content': '''
I am feeling: $cleanedMood

Talk to me naturally about this.
Do not give generic motivational quotes.
If something is difficult, help me understand the feeling and suggest
a practical next step.
''',
      }
    ]);
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  static Future<List<String>> getNourNotificationBatch() async {
    if (_openRouterKey.trim().isEmpty) {
      return _emergencyFallbackBatch();
    }

    const notificationPrompt = r'''
You are NOUR, a warm and intelligent spiritual life companion.

Create exactly 7 short notifications for different moments of a user's
day.

The messages should feel personally written, peaceful and meaningful,
not like generic AI quotes.

Themes:

1. Morning — fresh beginning and gratitude.
2. Hydration / short mindful pause.
3. Focus / productivity.
4. Rest / breathing / stretching.
5. Gentle spiritual encouragement.
6. Gratitude / Shukr.
7. Evening — calm reflection and rest.

Rules:

- Exactly 7 lines.
- One message per line.
- No numbering.
- No bullets.
- No quotation marks.
- Maximum one sentence per line.
- Do not repeat the same idea.
- Avoid excessive religious preaching.
- Do not invent Quran or Hadith quotations.
- Language: English.
''';

    final messages = [
      {
        'role': 'system',
        'content': notificationPrompt,
      },
      {
        'role': 'user',
        'content': 'Generate the 7 notifications now.',
      }
    ];

    for (final modelName in _fallbackModels) {
      final result = await _requestModel(
        modelName: modelName,
        messages: messages,
        useWebSearch: false,
      );

      if (result == null) continue;

      final parsed = result
          .split(RegExp(r'\r?\n'))
          .map(
            (line) => line
                .replaceFirst(
                  RegExp(r'^\s*[-*•]?\s*\d*[\.)]?\s*'),
                  '',
                )
                .trim(),
          )
          .where((line) => line.isNotEmpty)
          .toList();

      if (parsed.length >= 7) {
        return parsed.take(7).toList();
      }
    }

    return _emergencyFallbackBatch();
  }

  // ============================================================
  // BACKWARD COMPATIBILITY
  // ============================================================

  static Future<List<String>> getLuluNotificationBatch() {
    return getNourNotificationBatch();
  }

  // ============================================================
  // FALLBACK
  // ============================================================

  static String _connectionFallback() {
    return '''
I'm having trouble reaching my connection right now. Give me a moment and try again.
'''.trim();
  }

  static List<String> _emergencyFallbackBatch() {
    return [
      'Good morning. May today begin with a calm heart and a clear mind.',
      'Take a small pause, breathe deeply, and remember to drink some water.',
      'One focused step at a time is enough for now.',
      'Give your mind a moment to breathe before continuing.',
      'Whatever today brings, meet it with patience and steady courage.',
      'Notice one thing you can genuinely be grateful for today.',
      'Let the day settle gently, and give yourself permission to rest.',
    ];
  }
}