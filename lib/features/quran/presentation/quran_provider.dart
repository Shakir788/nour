import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
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
    required int ayah
  }) {
    state = LastRead(
      surahId: surahId,
      surahNameArabic: arabic,
      surahNameFrench: french,
      ayahNumber: ayah,
    );
  }
}

final lastReadProvider = StateNotifierProvider<LastReadNotifier, LastRead?>((ref) {
  return LastReadNotifier();

});

// ✨ AUDIO PLAYER LOGIC
class AudioStateNotifier extends StateNotifier<String?> {
  final AudioPlayer _player = AudioPlayer();

  AudioStateNotifier() : super(null) {
    // Jab audio khatam ho jaye, toh state wapas null kar do (Play icon wapas aa jayega)
    _player.onPlayerComplete.listen((_) {
      state = null;
    });
  }

  Future<void> togglePlay(String url) async {
    if (state == url) {
      // Agar same audio chal rahi hai, toh pause kar do
      await _player.pause();
      state = null;
    } else {
      // Nayi audio play karo
      await _player.play(UrlSource(url));
      state = url;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

// Ye provider hum UI mein 'Play/Pause' icon update karne ke liye use karenge
final audioStateProvider = StateNotifierProvider<AudioStateNotifier, String?>((ref) {
  return AudioStateNotifier();
});

final dailyQuranProgressProvider = StateProvider<double>((ref) => 0.0);
// ✨ Font Size Scale Provider for Quran Reader)
final quranFontSizeProvider = StateProvider<double>((ref) => 1.0);