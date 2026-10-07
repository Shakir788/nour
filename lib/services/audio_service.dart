import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SmartAudioPlayer {
  final AudioPlayer _player = AudioPlayer();
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  // 🔥 UI ko update rakhne ke liye streams expose kar diye
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;
  Stream<String> get logs => _player.onLog;

  /// Error ko caller tak bhejta hai (UI snackbar dikha sake).
  Future<void> playAudioFromUrl(String url) async {
    try {
      await stop(); // Naya gaana chalane se pehle purana clear karna zaroori hai

      FileInfo? fileInfo;
      try {
        fileInfo = await _cacheManager.getFileFromCache(url);
      } catch (e) {
        debugPrint("Cache read failed: $e");
      }

      if (fileInfo != null && fileInfo.file.existsSync()) {
        debugPrint("⚡ Playing from LOCAL CACHE");
        // Local file ke liye best approach
        await _player.setSourceDeviceFile(fileInfo.file.path);
        await _player.resume().timeout(const Duration(seconds: 15));
      } else {
        debugPrint("🌐 STREAMING from URL");
        // 🔥 FIX FOR ANDROID TIMEOUT ERROR: Direct play ki jagah setSource + resume use kiya aur timeout badha diya
        await _player.setSourceUrl(url);
        await _player.resume().timeout(const Duration(seconds: 40));

        // downloadFile() ek Future<FileInfo> deta hai (Stream nahi)
        unawaited(
          _cacheManager.downloadFile(url).then((_) {
            debugPrint("✅ Background cache complete");
          }).catchError((e) {
            debugPrint("⚠️ Background cache failed: $e");
          }),
        );
      }
    } catch (e) {
      debugPrint("❌ Smart Player Error: $e");
      rethrow;
    }
  }

  // 🛠️ Audio Context Settings (Screen off hone par bhi chalne ke liye)
  Future<void> setAudioContext() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setAudioContext(
      const AudioContext(
        android: AudioContextAndroid(
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.resume();
  Future<void> stop() async => await _player.stop();
  Future<void> seek(Duration position) async => await _player.seek(position);

  void dispose() {
    _player.stop();
    _player.dispose();
  }
}