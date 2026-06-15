import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SmartAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playAudioFromUrl(String url) async {
    // 1. Pehle check karo file cache mein hai ya nahi
    final file = await DefaultCacheManager().getSingleFile(url);
    
   
    await _player.play(DeviceFileSource(file.path));
  }

  void stop() => _player.stop();
}