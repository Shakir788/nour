import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';

class SleepAudioScreen extends ConsumerStatefulWidget {
  const SleepAudioScreen({super.key});

  @override
  ConsumerState<SleepAudioScreen> createState() => _SleepAudioScreenState();
}

class _SleepAudioScreenState extends ConsumerState<SleepAudioScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _lastError;

  // 🔥 Problematic tracks (heal.mp3 aur moula.mp3) yahan se remove kar diye gaye hain
  final List<Map<String, String>> _audioTracks = [
    {
      "title": "Calm & Serenity",
      "subtitle": "Peaceful vibes for sleep",
      "url": "https://cdn.jsdelivr.net/gh/Shakir788/nour_assets@main/calm.mp3",
      "icon": "🍃"
    },
    {
      "title": "Dhikr Rabbi",
      "subtitle": "Remembrance of Allah",
      "url": "https://cdn.jsdelivr.net/gh/Shakir788/nour_assets@main/rabbi.mp3",
      "icon": "📿"
    },
    {
      "title": "Sleep Ambience",
      "subtitle": "Stress Relief Nasheed",
      "url": "https://archive.org/download/stress-relief-dhikr-calm-your-heart-heal-your-soul_202610/-%20Stress%20Relief%20Islamic%20%2C%20Sleep%20Ambience%20-%20Nasheed%20Ambience.mp3",
      "icon": "🌙"
    },
    {
      "title": "99 Names of Allah",
      "subtitle": "1 Hour Peaceful Loop",
      "url": "https://archive.org/download/stress-relief-dhikr-calm-your-heart-heal-your-soul_202610/1%20HOUR%20LOOP%20-%2099%20Names%20of%20Allah%20-%20Easy%20to%20Memorize.mp3",
      "icon": "🕋"
    },
    {
      "title": "Ayat Shifa",
      "subtitle": "The Healing Verses",
      "url": "https://archive.org/download/stress-relief-dhikr-calm-your-heart-heal-your-soul_202610/Ayat%20Shifa%20-%20The%20Healing%20Verses%20-%20%D8%A7%D9%8A%D8%A7%D8%AA%20%D8%A7%D9%84%D8%B4%D9%81%D8%A7%D8%A1.mp3",
      "icon": "🌟"
    },
    {
      "title": "Deep Sleep & Rain",
      "subtitle": "Relaxing Islamic Music",
      "url": "https://archive.org/download/stress-relief-dhikr-calm-your-heart-heal-your-soul_202610/Islamic%20Relaxing%20Music%20Sleep%20with%20Rain%20Sound%20for%20Sleeping%2C%20Stress%20Relief%20Islamic%20Music%2C%20Deep%20Sleep.mp3",
      "icon": "🌧️"
    },
    {
      "title": "Surah Al Imran",
      "subtitle": "Quran for Sleeping & Protection",
      "url": "https://archive.org/download/stress-relief-dhikr-calm-your-heart-heal-your-soul_202610/Quran%20for%20Sleeping%20and%20Protection%20_%20Surah%20Al%20Imran%20Full.mp3",
      "icon": "📖"
    },
    {
      "title": "Relaxing Nasheed",
      "subtitle": "Study & Sleep with Rain",
      "url": "https://archive.org/download/stress-relief-dhikr-calm-your-heart-heal-your-soul_202610/Relaxing%20Nasheed%20for%20sleeping%20and%20study%20_%20Just%20feel%20this%20_%20With%20rain%20%F0%9F%8C%A7%EF%B8%8F%20sound%20%F0%9F%8E%A7%20%23nasheed.mp3",
      "icon": "🎧"
    },
    {
      "title": "Sacred Zikr",
      "subtitle": "1 Hour Instrumental",
      "url": "https://archive.org/download/stress-relief-dhikr-calm-your-heart-heal-your-soul_202610/Sacred%20Zikr%20for%20Deep%20Sleep%20%F0%9F%8C%99%20_%201%20Hour%20Islamic%20Sleep%20Instrumental%20Zikr%20_%20Peaceful%20Relaxing%20Nasheed.mp3",
      "icon": "🤍"
    },
    {
      "title": "Rain Ambience",
      "subtitle": "Peaceful sleep with rain",
      "url": "https://archive.org/download/stress-relief-dhikr-calm-your-heart-heal-your-soul_202610/Sleep%20with%20Rain%20Sound%20for%20Sleeping.mp3",
      "icon": "⛈"
    },
    {
      "title": "Calm Your Heart",
      "subtitle": "Stress Relief Dhikr",
      "url": "https://archive.org/download/stress-relief-dhikr-calm-your-heart-heal-your-soul_202610/Stress%20Relief%20Dhikr%20%F0%9F%8C%BF%20Calm%20Your%20Heart%20%26%20Heal%20Your%20Soul.mp3",
      "icon": "🕊️"
    },
    {
      "title": "Slowed & Reverb Naats",
      "subtitle": "Top 5 Relaxing Naats",
      "url": "https://archive.org/download/stress-relief-dhikr-calm-your-heart-heal-your-soul_202610/Top%205%20Naat%20%5BSlowed%2BReverb%5D%20-%20Relaxing%20Slowed%20Naat%20_%20thatnaazfatima7.mp3",
      "icon": "🕌"
    }
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (_isPlaying) _isLoading = false;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.onLog.listen((msg) {
      debugPrint("🔊 AudioPlayer log: $msg");
      _lastError = msg;
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
        _showError("Unable to play audio. Please check connection.");
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;
      if (_currentIndex < _audioTracks.length - 1) {
        _playTrack(_currentIndex + 1);
      } else {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _setupPlayer() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Player setup warning: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 4), 
      ),
    );
  }

  Future<void> _playTrack(int index) async {
    if (_currentIndex == index && _isPlaying) {
      await _audioPlayer.pause();
      return;
    }
    if (_currentIndex == index && !_isPlaying && !_isLoading && _duration > Duration.zero) {
      await _audioPlayer.resume();
      return;
    }

    setState(() {
      _currentIndex = index;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isLoading = true;
      _lastError = null;
    });

    final url = _audioTracks[index]["url"]!;

    try {
      await _audioPlayer.stop();

      FileInfo? fileInfo;
      try {
        fileInfo = await _cacheManager.getFileFromCache(url);
      } catch (e) {
        debugPrint("Cache read failed: $e");
      }

      if (fileInfo != null && fileInfo.file.existsSync()) {
        debugPrint("⚡ Playing from LOCAL CACHE");
        await _audioPlayer.setSourceDeviceFile(fileInfo.file.path);
        await _audioPlayer.resume().timeout(const Duration(seconds: 15));
      } else {
        debugPrint("🌐 STREAMING from URL: $url");
        
        await _audioPlayer.setSourceUrl(url); 
        await _audioPlayer.resume().timeout(const Duration(seconds: 40)); 

        unawaited(
          _cacheManager.downloadFile(url).then((_) {
            debugPrint("✅ Cached: ${_audioTracks[index]['title']}");
          }).catchError((e) {
            debugPrint("⚠️ Background cache failed: $e");
          }),
        );
      }

      if (mounted) setState(() => _isLoading = false);
    } on TimeoutException {
      debugPrint("❌ Audio timeout: $url");
      if (mounted) setState(() => _isLoading = false);
      _showError("Connection timeout. Please check your internet connection.");
    } catch (e) {
      debugPrint("❌ Audio Play Error: $e");
      if (mounted) setState(() => _isLoading = false);
      _showError("Failed to play the audio track.");
    }
  }

  void _seekTo(double seconds) {
    _audioPlayer.seek(Duration(seconds: seconds.toInt()));
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = _audioTracks[_currentIndex];
    final double maxSec = _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0;
    final double curSec = _position.inSeconds.toDouble().clamp(0.0, maxSec).toDouble();

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, color: AppColors.gold),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Peace & Sleep',
            style: AppTextStyles.displayMedium.copyWith(fontSize: 22, color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                opacity: 0.7,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _isPlaying ? AppColors.gold.withValues(alpha: 0.3) : Colors.black12,
                            blurRadius: _isPlaying ? 40 : 10,
                            spreadRadius: _isPlaying ? 10 : 2,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(currentTrack['icon']!, style: const TextStyle(fontSize: 60)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      currentTrack['title']!,
                      style: AppTextStyles.displayMedium.copyWith(fontSize: 24, color: AppColors.gold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentTrack['subtitle']!,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: AppColors.gold,
                        inactiveTrackColor: AppColors.textMuted.withValues(alpha: 0.3),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        min: 0,
                        max: maxSec,
                        value: curSec,
                        onChanged: _seekTo,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatTime(_position), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          Text(_formatTime(_duration), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(CupertinoIcons.backward_fill, color: Colors.white, size: 28),
                          onPressed: () {
                            if (_position.inSeconds > 10) {
                              _seekTo(_position.inSeconds.toDouble() - 10);
                            } else {
                              _seekTo(0);
                            }
                          },
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => _playTrack(_currentIndex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 3),
                                  )
                                : Icon(
                                    _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_arrow_solid,
                                    color: AppColors.background,
                                    size: 32,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(CupertinoIcons.forward_fill, color: Colors.white, size: 28),
                          onPressed: () {
                            if (_position.inSeconds < _duration.inSeconds - 10) {
                              _seekTo(_position.inSeconds.toDouble() + 10);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Collection", style: AppTextStyles.displayMedium.copyWith(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: _audioTracks.length,
                itemBuilder: (context, index) {
                  final track = _audioTracks[index];
                  final isSelected = _currentIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => _playTrack(index),
                      borderRadius: BorderRadius.circular(20),
                      child: GlassCard(
                        opacity: isSelected ? 0.6 : 0.2,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Text(track['icon']!, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track['title']!,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppColors.gold : Colors.white,
                                    ),
                                  ),
                                  Text(
                                    track['subtitle']!,
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected && _isPlaying)
                              const Icon(CupertinoIcons.waveform_path, color: AppColors.gold)
                            else if (isSelected && _isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: AppColors.textMuted, strokeWidth: 2),
                              )
                            else
                              const Icon(CupertinoIcons.play_circle, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}