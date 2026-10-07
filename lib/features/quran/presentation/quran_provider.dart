import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

// ─── Last Read ────────────────────────────────────────────────────
class LastRead {
  final int surahId;
  final String surahNameArabic;
  final String surahNameFrench;
  final int ayahNumber;

  LastRead({
    required this.surahId,
    required this.surahNameArabic,
    required this.surahNameFrench,
    required this.ayahNumber,
  });
}

class LastReadNotifier extends StateNotifier<LastRead?> {
  LastReadNotifier() : super(null);

  void updateLastRead({
    required int surahId,
    required String arabic,
    required String french,
    required int ayah,
  }) {
    state = LastRead(
      surahId: surahId,
      surahNameArabic: arabic,
      surahNameFrench: french,
      ayahNumber: ayah,
    );
  }
}

final lastReadProvider =
    StateNotifierProvider<LastReadNotifier, LastRead?>((ref) {
  return LastReadNotifier();
});

// ─── Current Ayah Index Provider (Glow aur Scroll ke liye) ────────
final currentAyahIndexProvider = StateProvider<int>((ref) => -1);

// ─── NEW: Current Word Index (ayah ke andar kaun sa lafz bola ja raha hai) ──
// -1 = koi word highlight nahi
final currentWordIndexProvider = StateProvider<int>((ref) => -1);

// ─── Word helpers (UI aur audio dono yahi use karte hain, taaki index match rahe) ──
List<String> splitAyahWords(String text) {
  return text
      .split(RegExp(r'\s+'))
      .where((w) => w.trim().isNotEmpty)
      .toList();
}

/// Ek word kitna lamba bola jayega, uska andaza (relative weight).
/// Harf zyada = zyada waqt. Shadda aur madd (lambi awaaz) ko extra weight.
double _wordWeight(String word) {
  int letters = 0;
  int shadda = 0;
  int madd = 0;
  for (final r in word.runes) {
    if (r == 0x0651) shadda++; // shadda
    if (r == 0x0653) madd++; // maddah
    final isMark = (r >= 0x064B && r <= 0x065F) ||
        r == 0x0670 ||
        (r >= 0x06D6 && r <= 0x06ED) ||
        r == 0x0640;
    if (!isMark) letters++;
  }
  return letters + shadda * 1.0 + madd * 3.0 + 1.0;
}

/// cum[0] = 0, cum[i] = pehle i words ka total weight
List<double> _cumulativeWeights(String text) {
  final words = splitAyahWords(text);
  final cum = <double>[0.0];
  for (final w in words) {
    cum.add(cum.last + _wordWeight(w));
  }
  return cum;
}

// ─── Audio Player ─────────────────────────────────────────────────
class AudioStateNotifier extends StateNotifier<String?> {
  final Ref ref;
  final AudioPlayer _player = AudioPlayer();

  List<String> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaylistMode = false;

  // Word highlight ke liye
  List<String>? _ayahTexts; // null = word highlight band (jaise translation audio me)
  List<double>? _weights; // current ayah ke cumulative word weights
  Duration _duration = Duration.zero;

  // Tuning: ayah audio ke shuru/aakhir me jo khamoshi hoti hai (milliseconds)
  static const double _leadInMs = 120;
  static const double _tailMs = 250;

  // ── SYNC TUNING ──────────────────────────────────────────────
  // Highlight awaaz se kitna AAGE rakhna hai (ms). Glow peeche lage to badhao,
  // aage lage to ghatao. Audio latency + screen delay ko compensate karta hai.
  static const double _syncLeadMs = 180;
  static const double _playbackRate = 1.4;

  // Position beech me interpolate karne ke liye
  Timer? _ticker;
  Duration _lastPos = Duration.zero;
  final Stopwatch _sinceLastPos = Stopwatch();

  AudioStateNotifier(this.ref) : super(null) {
    _player.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ));

    _player.onPlayerComplete.listen((_) {
      if (_isPlaylistMode) {
        _playNextInPlaylist();
      } else {
        state = null;
        ref.read(currentAyahIndexProvider.notifier).state = -1;
        _resetWord();
      }
    });

    _player.onPlayerStateChanged.listen((PlayerState playerState) {
      if (playerState == PlayerState.playing) {
        _player.setPlaybackRate(_playbackRate);
        _startTicker();
      } else {
        _stopTicker();
      }
    });

    _player.onDurationChanged.listen((d) => _duration = d);
    _player.onPositionChanged.listen(_onPosition);
  }

  // ── Word tracking ──────────────────────────────────────────────
  void _resetWord() {
    _weights = null;
    _duration = Duration.zero;
    _lastPos = Duration.zero;
    _sinceLastPos
      ..stop()
      ..reset();
    final n = ref.read(currentWordIndexProvider.notifier);
    if (n.state != -1) n.state = -1;
  }

  void _prepareAyah(int index) {
    _duration = Duration.zero;
    _lastPos = Duration.zero;
    _sinceLastPos
      ..stop()
      ..reset();
    final texts = _ayahTexts;
    if (texts != null && index >= 0 && index < texts.length) {
      _weights = _cumulativeWeights(texts[index]);
      ref.read(currentWordIndexProvider.notifier).state = 0;
    } else {
      _weights = null;
      ref.read(currentWordIndexProvider.notifier).state = -1;
    }
  }

  // Player ki asli position (~200ms me ek baar aati hai) = reference point.
  // Beech ka waqt ticker se smooth nikalte hain, taaki highlight peeche na rahe.
  void _onPosition(Duration pos) {
    _lastPos = pos;
    _sinceLastPos
      ..reset()
      ..start();
    _updateWordAt(pos.inMilliseconds + _syncLeadMs);
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_sinceLastPos.isRunning) return;
      final est = _lastPos.inMilliseconds +
          _sinceLastPos.elapsedMilliseconds * _playbackRate;
      _updateWordAt(est + _syncLeadMs);
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _sinceLastPos.stop();
  }

  void _updateWordAt(double tMs) {
    final w = _weights;
    if (!_isPlaylistMode || w == null || w.length < 2) return;
    final totalMs = _duration.inMilliseconds.toDouble();
    if (totalMs <= 0) return;

    final startMs = _leadInMs;
    final endMs = totalMs - _tailMs;
    if (endMs <= startMs) return;

    int idx = 0;
    if (tMs > startMs) {
      final frac = ((tMs - startMs) / (endMs - startMs)).clamp(0.0, 1.0);
      final target = frac * w.last;
      while (idx < w.length - 2 && target >= w[idx + 1]) {
        idx++;
      }
    }

    // Sirf aage badho (interpolation ki wajah se glow peeche na kude)
    final notifier = ref.read(currentWordIndexProvider.notifier);
    if (idx > notifier.state) notifier.state = idx;
  }

  // ── Playback ──────────────────────────────────────────────────
  Future<void> togglePlay(String url) async {
    _isPlaylistMode = false;
    _ayahTexts = null;
    _resetWord();
    ref.read(currentAyahIndexProvider.notifier).state = -1;
    try {
      if (state == url) {
        await _player.pause();
        state = null;
      } else {
        await _player.stop();
        await _player.setSourceUrl(url);
        await _player.resume();
        state = url;
      }
    } catch (e) {
      debugPrint('❌ Audio Play Error: $e');
      state = null;
    }
  }

  /// arabicTexts: har ayah ka arabic text (urls ke barabar length).
  /// Do to word-by-word glow chalta hai. null do to sirf ayah-level glow (translation audio).
  Future<void> startPlaylist(
    List<String> urls, {
    int startIndex = 0,
    List<String>? arabicTexts,
  }) async {
    if (urls.isEmpty) return;
    _playlist = urls;
    _isPlaylistMode = true;
    _currentIndex = startIndex;
    _ayahTexts =
        (arabicTexts != null && arabicTexts.length == urls.length) ? arabicTexts : null;
    ref.read(currentAyahIndexProvider.notifier).state = _currentIndex;
    _prepareAyah(_currentIndex);
    try {
      await _player.stop();
      await _player.setSourceUrl(_playlist[_currentIndex]);
      await _player.resume();
      state = _playlist[_currentIndex];
    } catch (e) {
      debugPrint('❌ Playlist Play Error: $e');
      _isPlaylistMode = false;
      state = null;
      ref.read(currentAyahIndexProvider.notifier).state = -1;
      _resetWord();
    }
  }

  Future<void> _playNextInPlaylist() async {
    _currentIndex++;
    if (_currentIndex < _playlist.length) {
      ref.read(currentAyahIndexProvider.notifier).state = _currentIndex;
      _prepareAyah(_currentIndex);
      try {
        await _player.stop();
        await _player.setSourceUrl(_playlist[_currentIndex]);
        await _player.resume();
        state = _playlist[_currentIndex];
      } catch (e) {
        debugPrint('❌ Next Track Error: $e');
        _isPlaylistMode = false;
        state = null;
        ref.read(currentAyahIndexProvider.notifier).state = -1;
        _resetWord();
      }
    } else {
      _isPlaylistMode = false;
      _currentIndex = -1;
      ref.read(currentAyahIndexProvider.notifier).state = -1;
      state = null;
      _resetWord();
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {}
    _isPlaylistMode = false;
    _currentIndex = -1;
    _ayahTexts = null;
    ref.read(currentAyahIndexProvider.notifier).state = -1;
    state = null;
    _resetWord();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final audioStateProvider =
    StateNotifierProvider<AudioStateNotifier, String?>((ref) {
  return AudioStateNotifier(ref);
});

// ─── Providers ────────────────────────────────────────────────────
final quranFontSizeProvider = StateProvider<double>((ref) => 1.0);
final dailyQuranProgressProvider = StateProvider<double>((ref) => 0.0);

// ─── Qari List ────────────────────────────────────────────────────
const List<Map<String, String>> qariList = [
  {'id': 'ar.alafasy', 'name': 'Mishary Rashid Alafasy'},
  {'id': 'ar.abdulbasitmurattal', 'name': 'Abdul Basit'},
  {'id': 'ar.abdurrahmaansudais', 'name': 'Abdur-Rahman as-Sudais'},
  {'id': 'ar.mahermuaiqly', 'name': 'Maher Al Muaiqly'},
  {'id': 'ar.husary', 'name': 'Mahmoud Khalil Al-Husary'},
];

final selectedQariProvider = StateProvider<String>((ref) => 'ar.alafasy');

// ─── Translation Languages ────────────────────────────────────────
const List<Map<String, String>> translationEditions = [
  {'name': 'English', 'flag': '🇬🇧', 'id': 'en.asad'},
  {'name': 'French', 'flag': '🇫🇷', 'id': 'fr.hamidullah'},
  {'name': 'Urdu', 'flag': '🇵🇰', 'id': 'ur.jalandhry'},
  {'name': 'Hindi', 'flag': '🇮🇳', 'id': 'hi.hindi'},
  {'name': 'Spanish', 'flag': '🇪🇸', 'id': 'es.asad'},
  {'name': 'Turkish', 'flag': '🇹🇷', 'id': 'tr.diyanet'},
  {'name': 'Indonesian', 'flag': '🇮🇩', 'id': 'id.indonesian'},
  {'name': 'Russian', 'flag': '🇷🇺', 'id': 'ru.kuliev'},
  {'name': 'German', 'flag': '🇩🇪', 'id': 'de.bubenheim'},
  {'name': 'Bengali', 'flag': '🇧🇩', 'id': 'bn.bengali'},
];

final selectedTranslationProvider =
    StateProvider<String>((ref) => 'en.asad');

// ─── Audio Playback Mode & Map ───────────────────────────────
enum AudioPlaybackMode { arabic, translation }

final audioPlaybackModeProvider =
    StateProvider<AudioPlaybackMode>((ref) => AudioPlaybackMode.arabic);

const Map<String, String> translationAudioMap = {
  'en.asad': 'en.walk',
  'fr.hamidullah': 'fr.leclerc',
  'ur.jalandhry': 'ur.khan',
  'ru.kuliev': 'ru.kuliev-audio',
};