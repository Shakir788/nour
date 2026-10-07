import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:page_flip/page_flip.dart';

import '../../../core/theme/app_theme.dart';
import '../presentation/habit_provider.dart';
import '../../mood/presentation/mood_provider.dart';
// ✨ FIXED: Updated the import to the new Nour service
import '../../../core/services/nour_diary_reaction_service.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _pageFlipController = GlobalKey<PageFlipWidgetState>();
  final LocalAuthentication auth = LocalAuthentication();

  DateTime _currentDate = DateTime.now();

  bool _isLocked = true;
  bool _authFailed = false;
  int _currentThemeIndex = 0;

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _asmrPlayer = AudioPlayer();
  int _asmrIndex = 0;
  bool _isAsmrPlaying = false;
  bool _isAsmrLoading = false;
  Duration _asmrDuration = Duration.zero;
  Duration _asmrPosition = Duration.zero;

  double _dragStartX = 0.0;

  final List<String> asmrNames = [
    "Off",
    "Calm & Serenity 🍃",
    "Healing Soul ✨",
    "Ya Moula 🤲",
    "Dhikr Rabbi 📿",
    "Relief 🕊️",
  ];

  final List<String> asmrFiles = [
    "",
    "https://raw.githubusercontent.com/Shakir788/nour_assets/main/calm.mp3",
    "https://raw.githubusercontent.com/Shakir788/nour_assets/main/heal.mp3",
    "https://raw.githubusercontent.com/Shakir788/nour_assets/main/moula.mp3",
    "https://raw.githubusercontent.com/Shakir788/nour_assets/main/rabbi.mp3",
    "https://raw.githubusercontent.com/Shakir788/nour_assets/main/relief.mp3",
  ];

  @override
  void initState() {
    super.initState();
    _authenticate();
    _initPlayerListeners();
    _loadPlayerState();
  }

  @override
  void dispose() {
    _sfxPlayer.dispose();
    _asmrPlayer.stop();
    _asmrPlayer.dispose();
    super.dispose();
  }

  void _playPageFlipSound() {
    try {
      _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      _sfxPlayer.play(AssetSource('audio/flip.mp3'));
    } catch (e) {
      debugPrint("Flip sound error: $e");
    }
  }

  void _initPlayerListeners() {
    _asmrPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _asmrDuration = d);
    });
    _asmrPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() => _asmrPosition = p);
        _savePlayerState();
      }
    });
    _asmrPlayer.onPlayerComplete.listen((event) {
      if (mounted) _playNext();
    });
  }

  Future<void> _loadPlayerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('last_asmr_index') ?? 0;
    final savedPositionMs = prefs.getInt('last_asmr_position') ?? 0;

    if (savedIndex > 0 && savedIndex < asmrFiles.length) {
      setState(() {
        _asmrIndex = savedIndex;
        _asmrPosition = Duration(milliseconds: savedPositionMs);
      });
      DefaultCacheManager().getSingleFile(asmrFiles[_asmrIndex]);
    }
  }

  Future<void> _savePlayerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_asmr_index', _asmrIndex);
    await prefs.setInt('last_asmr_position', _asmrPosition.inMilliseconds);
  }

  Future<void> _toggleAsmrPlay() async {
    if (_asmrIndex == 0) {
      _playNext();
      return;
    }
    try {
      if (_isAsmrPlaying) {
        await _asmrPlayer.pause();
        setState(() => _isAsmrPlaying = false);
      } else {
        setState(() => _isAsmrLoading = true);
        await _asmrPlayer.setReleaseMode(ReleaseMode.loop);
        final file = await DefaultCacheManager().getSingleFile(asmrFiles[_asmrIndex]);
        await _asmrPlayer.play(DeviceFileSource(file.path));
        await _asmrPlayer.seek(_asmrPosition);
        if (mounted) {
          setState(() {
            _isAsmrPlaying = true;
            _isAsmrLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Player Toggle Error: $e");
      if (mounted) setState(() => _isAsmrLoading = false);
    }
  }

  Future<void> _playNext() async {
    int nextIndex = (_asmrIndex + 1) % asmrFiles.length;
    if (nextIndex == 0) nextIndex = 1;

    setState(() {
      _asmrIndex = nextIndex;
      _asmrPosition = Duration.zero;
      _isAsmrLoading = true;
    });

    try {
      await _asmrPlayer.stop();
      await _asmrPlayer.setReleaseMode(ReleaseMode.loop);
      final file = await DefaultCacheManager().getSingleFile(asmrFiles[_asmrIndex]);
      await _asmrPlayer.play(DeviceFileSource(file.path));
      if (mounted) {
        setState(() {
          _isAsmrPlaying = true;
          _isAsmrLoading = false;
        });
      }
      _savePlayerState();
    } catch (e) {
      debugPrint("Play next error: $e");
      if (mounted) setState(() => _isAsmrLoading = false);
    }
  }

  Future<void> _fastForward() async {
    if (_asmrIndex == 0) return;
    final newPosition = _asmrPosition + const Duration(seconds: 10);
    if (newPosition < _asmrDuration) {
      await _asmrPlayer.seek(newPosition);
    } else {
      _playNext();
    }
  }

  void _closeMusicPlayer() {
    _asmrPlayer.pause();
    setState(() {
      _isAsmrPlaying = false;
      _asmrIndex = 0;
    });
  }

  Future<void> _authenticate() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Unlock your secure journal 🔐',
      );
      if (authenticated) {
        setState(() {
          _isLocked = false;
          _authFailed = false;
        });
      } else {
        setState(() => _authFailed = true);
      }
    } catch (e) {
      debugPrint("Auth error: $e");
      setState(() => _isLocked = false);
    }
  }

  Color _getBackgroundColor() {
    if (_currentThemeIndex == 0) return const Color(0xFFFFFDF2);
    if (_currentThemeIndex == 1) return const Color(0xFFFFF0F5);
    return const Color(0xFFF6F8FF);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return _LockScreen(authFailed: _authFailed, onUnlock: _authenticate);
    }

    final mood = ref.watch(moodNotifierProvider);
    final moodTint = DiaryPhysicalPage.getMoodTint(mood?.moodType);
    
    final double paddingTop = MediaQuery.of(context).padding.top;
    final double headerHeight = paddingTop + 150.0;

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textDark),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              DateFormat('EEEE').format(_currentDate).toUpperCase(),
              style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w600, color: AppTheme.primaryPink, fontSize: 11, letterSpacing: 1.2),
            ),
            Text(
              DateFormat('dd MMMM yyyy').format(_currentDate),
              style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), shape: BoxShape.circle),
              child: const Icon(Icons.palette_outlined, size: 18, color: AppTheme.textDark),
            ),
            onPressed: () => setState(() => _currentThemeIndex = (_currentThemeIndex + 1) % 3),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Listener(
            onPointerDown: (event) => _dragStartX = event.position.dx,
            onPointerUp: (event) {
              final delta = event.position.dx - _dragStartX;
              if (delta.abs() > 40) {
                _playPageFlipSound();
              }
            },
            child: PageFlipWidget(
              key: _pageFlipController,
              initialIndex: 364, 
              backgroundColor: _getBackgroundColor(),
              lastPage: Container(
                color: _getBackgroundColor(),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: NotebookPainter(
                          lineHeight: 32.0, 
                          themeIndex: _currentThemeIndex, 
                          moodTint: moodTint, 
                          currentDate: _currentDate,
                          headerHeight: headerHeight,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: moodTint.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 6)
                              ],
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, size: 42, color: AppTheme.primaryPink),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "End of Capsule ⏳",
                            style: TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Come back tomorrow to write\na new page.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              children: <Widget>[
                for (var index = 364; index >= 0; index--)
                  DiaryPhysicalPage(
                    pageDate: DateTime.now().subtract(Duration(days: index)),
                    themeIndex: _currentThemeIndex,
                    onDateFocused: (date) {
                      if (mounted && _currentDate != date) {
                        Future.microtask(() => setState(() => _currentDate = date));
                      }
                    },
                    onPlayNextAsmr: _playNext,
                  ),
              ],
            ),
          ),

          Positioned(
            left: 0, top: 150, bottom: 150, width: 40,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _playPageFlipSound();
                _pageFlipController.currentState?.nextPage();
              },
            ),
          ),
          Positioned(
            right: 0, top: 150, bottom: 150, width: 40,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _playPageFlipSound();
                _pageFlipController.currentState?.previousPage();
              },
            ),
          ),
          
          if (_asmrIndex > 0)
            Positioned(
              bottom: 90, 
              left: 16,
              right: 16,
              child: _WowMusicPlayerCard(
                title: asmrNames[_asmrIndex],
                isPlaying: _isAsmrPlaying,
                isLoading: _isAsmrLoading,
                position: _asmrPosition,
                duration: _asmrDuration,
                moodTint: moodTint,
                onTogglePlay: _toggleAsmrPlay,
                onFastForward: _fastForward,
                onNext: _playNext,
                onClose: _closeMusicPlayer, 
                onSeek: (value) async {
                  final newPos = Duration(milliseconds: value.toInt());
                  await _asmrPlayer.seek(newPos);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LockScreen extends StatelessWidget {
  final bool authFailed;
  final VoidCallback onUnlock;
  const _LockScreen({required this.authFailed, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F5), Color(0xFFFFFDF2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primaryPink.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 6)],
                ),
                child: const Icon(Icons.lock_rounded, size: 64, color: AppTheme.primaryPink),
              ),
              const SizedBox(height: 28),
              const Text("Protected Journal 💗", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              Text(
                authFailed ? "Authentication failed, please try again ✨" : "Your thoughts, safe and secure",
                style: TextStyle(fontSize: 13, color: AppTheme.textLight.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 6,
                  shadowColor: AppTheme.primaryPink.withValues(alpha: 0.5),
                ),
                onPressed: onUnlock,
                icon: const Icon(Icons.fingerprint_rounded, color: Colors.white),
                label: const Text("Unlock", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WowMusicPlayerCard extends StatelessWidget {
  final String title;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final Color moodTint;
  final VoidCallback onTogglePlay;
  final VoidCallback onFastForward;
  final VoidCallback onNext;
  final VoidCallback onClose;
  final ValueChanged<double> onSeek;

  const _WowMusicPlayerCard({
    required this.title,
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.duration,
    required this.moodTint,
    required this.onTogglePlay,
    required this.onFastForward,
    required this.onNext,
    required this.onClose,
    required this.onSeek,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final posMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                AppTheme.primaryPink.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPink.withValues(alpha: 0.15),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: moodTint.withValues(alpha: 0.1),
                          boxShadow: isPlaying
                              ? [BoxShadow(color: moodTint.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)]
                              : [],
                        ),
                      ),
                      _VinylDisc(isPlaying: isPlaying, moodTint: moodTint),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textDark, letterSpacing: 0.2),
                              ),
                            ),
                            GestureDetector(
                              onTap: onClose,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.textDark.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close_rounded, size: 14, color: AppTheme.textDark.withValues(alpha: 0.6)),
                              ),
                            ),
                            const SizedBox(width: 6), 
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoading ? "Loading..." : (isPlaying ? "Playing ✨" : "Paused"),
                          style: TextStyle(fontSize: 11.5, color: AppTheme.textLight.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  _WowIconButton(icon: Icons.forward_10_rounded, onTap: onFastForward, size: 22),
                  const SizedBox(width: 2),
                  _WowIconButton(icon: Icons.skip_next_rounded, onTap: onNext, size: 24),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onTogglePlay,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [moodTint, moodTint.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: moodTint.withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: isPlaying ? 2 : 0,
                          ),
                        ],
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(_fmt(position), style: TextStyle(fontSize: 10, color: AppTheme.textLight.withValues(alpha: 0.6), fontWeight: FontWeight.w700)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: moodTint,
                        inactiveTrackColor: moodTint.withValues(alpha: 0.15),
                        thumbColor: moodTint,
                        overlayColor: moodTint.withValues(alpha: 0.15),
                      ),
                      child: Slider(value: posMs, max: maxMs, onChanged: onSeek),
                    ),
                  ),
                  Text(_fmt(duration), style: TextStyle(fontSize: 10, color: AppTheme.textLight.withValues(alpha: 0.6), fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _WowIconButton({required this.icon, required this.onTap, required this.size});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: AppTheme.textDark.withValues(alpha: 0.6), size: size),
      ),
    );
  }
}

class _VinylDisc extends StatefulWidget {
  final bool isPlaying;
  final Color moodTint;
  const _VinylDisc({required this.isPlaying, required this.moodTint});

  @override
  State<_VinylDisc> createState() => _VinylDiscState();
}

class _VinylDiscState extends State<_VinylDisc> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    if (!widget.isPlaying) _controller.stop();
  }

  @override
  void didUpdateWidget(covariant _VinylDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.black87, Color(0xFF2D2D2D)],
            stops: [0.3, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.moodTint.withValues(alpha: 0.9),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class DiaryPhysicalPage extends ConsumerStatefulWidget {
  final DateTime pageDate;
  final int themeIndex;
  final Function(DateTime) onDateFocused;
  final VoidCallback onPlayNextAsmr;

  const DiaryPhysicalPage({
    super.key,
    required this.pageDate,
    required this.themeIndex,
    required this.onDateFocused,
    required this.onPlayNextAsmr,
  });

  static Color getMoodTint(String? moodType) {
    switch (moodType) {
      case "Sad": return const Color(0xFFAEC6E8);
      case "Stressed": return const Color(0xFFE8B4AE);
      case "Happy": return const Color(0xFFFFE08A);
      case "Tired": return const Color(0xFFC9B8E8);
      default: return AppTheme.primaryPink;
    }
  }

  @override
  ConsumerState<DiaryPhysicalPage> createState() => _DiaryPhysicalPageState();
}

class _DiaryPhysicalPageState extends ConsumerState<DiaryPhysicalPage> {
  final TextEditingController _gratitudeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 4,
    penColor: AppTheme.primaryPink,
    exportBackgroundColor: Colors.white,
  );

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  bool _isMagicInkActive = false;
  bool _isTextRevealed = false;

  String? _nourReaction;
  bool _nourThinking = false;
  DateTime? _lastEditTime;

  String? _memoryText;
  int? _memoryYearsAgo;

  final List<String> dailyPrompts = [
    "What made you smile today? ✨",
    "What are you grateful for today? 🌸",
    "What was the best part of your day? 💖",
    "How did you take care of yourself today? 💧",
  ];
  final List<String> stickerOptions = ['🌸', '💖', '✨', '☕', '🦋', '📖', '🤲'];

  @override
  void initState() {
    super.initState();
    _loadPageData();
    _loadOnThisDayMemory();
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
    widget.onDateFocused(widget.pageDate);
  }

  @override
  void dispose() {
    _gratitudeController.dispose();
    _signatureController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String get _dateKey => "diary_${DateFormat('yyyy_MM_dd').format(widget.pageDate)}";
  String get _nourReactionKey => "nour_reaction_$_dateKey";

  Future<void> _loadPageData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedText = prefs.getString(_dateKey) ?? "";
    final savedReaction = prefs.getString(_nourReactionKey);
    if (mounted) {
      setState(() {
        _gratitudeController.text = savedText;
        _nourReaction = savedReaction;
      });
    }
    Future.microtask(() => ref.read(habitNotifierProvider.notifier).updateGratitude(savedText));
  }

  Future<void> _savePageData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, _gratitudeController.text);
    ref.read(habitNotifierProvider.notifier).updateGratitude(_gratitudeController.text);
  }

  Future<void> _clearCurrentPage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dateKey);
    await prefs.remove(_nourReactionKey);
    setState(() {
      _gratitudeController.clear();
      _nourReaction = null;
    });
    ref.read(habitNotifierProvider.notifier).updateGratitude("");
  }

  Future<void> _scheduleNourReaction() async {
    final editTime = DateTime.now();
    _lastEditTime = editTime;
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted || _lastEditTime != editTime) return;

    final text = _gratitudeController.text.trim();
    if (text.length < 8) return;

    setState(() => _nourThinking = true);
    // ✨ FIXED: Calling the updated service
    final reaction = await NourDiaryReactionService.reactToEntry(text);
    if (!mounted) return;

    setState(() {
      _nourThinking = false;
      if (reaction != null) _nourReaction = reaction;
    });

    if (reaction != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nourReactionKey, reaction);
    }
  }

  Future<void> _loadOnThisDayMemory() async {
    final prefs = await SharedPreferences.getInstance();
    for (int yearsAgo = 1; yearsAgo <= 5; yearsAgo++) {
      final pastDate = DateTime(widget.pageDate.year - yearsAgo, widget.pageDate.month, widget.pageDate.day);
      final key = "diary_${DateFormat('yyyy_MM_dd').format(pastDate)}";
      final text = prefs.getString(key);
      if (text != null && text.trim().length > 5) {
        if (mounted) {
          setState(() {
            _memoryText = text.trim();
            _memoryYearsAgo = yearsAgo;
          });
        }
        return;
      }
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear Page? 📝", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        content: const Text("Do you really want to clear all content on this page?", style: TextStyle(color: AppTheme.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              _clearCurrentPage();
              Navigator.pop(context);
            },
            child: const Text("Clear", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addSticker(String sticker) {
    _gratitudeController.text = '${_gratitudeController.text} $sticker';
    _gratitudeController.selection = TextSelection.collapsed(offset: _gratitudeController.text.length);
    _savePageData();
    _scheduleNourReaction();
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
        });
        if (path != null) ref.read(habitNotifierProvider.notifier).updateAudio(path);
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final String path = '${dir.path}/journal_audio_${widget.pageDate.millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() => _isRecording = true);
        }
      }
    } catch (e) {
      debugPrint("Audio Record Error: $e");
    }
  }

  Future<void> _togglePlayback(String? dbAudioPath) async {
    final pathToPlay = _recordedFilePath ?? dbAudioPath;
    if (pathToPlay == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(pathToPlay));
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _deleteVoiceNote(String? dbAudioPath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Voice Note? 🎙️", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        content: const Text("This action is irreversible.", style: TextStyle(color: AppTheme.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel", style: TextStyle(color: AppTheme.textLight))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _audioPlayer.stop();
      try {
        final pathToDelete = _recordedFilePath ?? dbAudioPath;
        if (pathToDelete != null) {
          final file = File(pathToDelete);
          if (await file.exists()) await file.delete();
        }
      } catch (e) {
        debugPrint("File delete error: $e");
      }
      setState(() {
        _isPlaying = false;
        _recordedFilePath = null;
      });
      ref.read(habitNotifierProvider.notifier).updateAudio('');
    }
  }

  void _openDoodleBoard() {
    _signatureController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Draw your thoughts 🎨", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
            child: Signature(controller: _signatureController, height: 300, backgroundColor: Colors.white),
          ),
        ),
        actions: [
          TextButton(onPressed: () => _signatureController.clear(), child: const Text("Clear", style: TextStyle(color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (_signatureController.isNotEmpty) {
                final Uint8List? data = await _signatureController.toPngBytes();
                if (data != null) {
                  final dir = await getApplicationDocumentsDirectory();
                  final File file = File('${dir.path}/doodle_${widget.pageDate.millisecondsSinceEpoch}.png');
                  await file.writeAsBytes(data);
                  ref.read(habitNotifierProvider.notifier).updateImage(file.path);
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) ref.read(habitNotifierProvider.notifier).updateImage(image.path);
  }

  void _saveAndShowAffirmation(String? moodType) {
    String affirmation = "Every day is a new beginning. You are doing an amazing job. ✨";
    if (moodType == "Sad") {
      affirmation = "It's normal not to be perfect every day. Take a deep breath. Tomorrow will be softer. 🌧️💖";
    } else if (moodType == "Stressed") {
      affirmation = "Drop your shoulders. Close your eyes for a second. You deserve to rest. 🍃✨";
    } else if (moodType == "Happy") {
      affirmation = "Keep that smile! Your light illuminates everything around you. ☀️🌸";
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: AppTheme.primaryPink.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 4)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: AppTheme.primaryPink, size: 48),
              const SizedBox(height: 24),
              Text(
                affirmation,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontFamily: 'serif', fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: AppTheme.textDark, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.textDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickUnlockDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryPink, onPrimary: Colors.white, onSurface: AppTheme.textDark),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      ref.read(habitNotifierProvider.notifier).setUnlockDate(formattedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("⏳ Capsule sealed until $formattedDate!"),
          backgroundColor: AppTheme.textDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitNotifierProvider);
    final currentMood = ref.watch(moodNotifierProvider);

    final String todayPrompt = dailyPrompts[widget.pageDate.day % dailyPrompts.length];
    String vibeText = "Daily Vibe: Peaceful 🍃";
    if (currentMood?.moodType == "Happy") vibeText = "Daily Vibe: Radiant ☀️";
    if (currentMood?.moodType == "Tired") vibeText = "Daily Vibe: Tired ☕";
    if (currentMood?.moodType == "Sad") vibeText = "Daily Vibe: Cloudy 🌧️";
    if (currentMood?.moodType == "Stressed") vibeText = "Daily Vibe: Tense 🌪️";

    bool applyBlur = _isMagicInkActive && !_isTextRevealed;
    final hasVoiceNote = habits?.audioPath != null && habits!.audioPath!.isNotEmpty || _recordedFilePath != null;
    final moodTint = DiaryPhysicalPage.getMoodTint(currentMood?.moodType);

    final double paddingTop = MediaQuery.of(context).padding.top;
    final double headerHeight = paddingTop + 150.0;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: NotebookPainter(
              lineHeight: 32.0, 
              themeIndex: widget.themeIndex, 
              moodTint: moodTint, 
              currentDate: widget.pageDate,
              headerHeight: headerHeight,
            ),
          ),
        ),
        
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60), 
              
              SizedBox(
                height: headerHeight - (paddingTop + 60),
                child: Padding(
                  padding: const EdgeInsets.only(left: 85, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: moodTint.withValues(alpha: 0.4)),
                            ),
                            child: Text(vibeText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_gratitudeController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 22), 
                                  onPressed: _showClearConfirmation,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _saveAndShowAffirmation(currentMood?.moodType), 
                                child: const Text("Finish 💗", style: TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold, fontSize: 14))
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(todayPrompt, style: const TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, fontSize: 14)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 140, left: 85, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_memoryText != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _OnThisDayBanner(text: _memoryText!, yearsAgo: _memoryYearsAgo!),
                          ),

                        if (habits != null && habits.unlockDate != null && habits.unlockDate!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [AppTheme.textDark, AppTheme.textDark.withValues(alpha: 0.85)]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: AppTheme.textDark.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.hourglass_bottom_rounded, color: AppTheme.primaryPink, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text("Capsule sealed until ${habits.unlockDate}",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        GestureDetector(
                          onLongPressDown: (_) => setState(() => _isTextRevealed = true),
                          onLongPressUp: () => setState(() => _isTextRevealed = false),
                          onLongPressCancel: () => setState(() => _isTextRevealed = false),
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: applyBlur ? 6.0 : 0.0, sigmaY: applyBlur ? 6.0 : 0.0),
                            child: TextField(
                              controller: _gratitudeController,
                              maxLines: null,
                              minLines: 5,
                              onChanged: (text) {
                                _savePageData();
                                _scheduleNourReaction();
                              },
                              style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50), fontFamily: 'serif', fontWeight: FontWeight.w600, height: 2.0),
                              decoration: InputDecoration(
                                hintText: "Dear journal...",
                                hintStyle: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.3), fontStyle: FontStyle.italic),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),

                        if (applyBlur)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text("👀 Hold to reveal your secret text",
                                style: TextStyle(fontSize: 11, color: AppTheme.textLight.withValues(alpha: 0.7), fontStyle: FontStyle.italic)),
                          ),

                        if (_nourThinking || _nourReaction != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 15, bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.auto_awesome, color: AppTheme.primaryPink, size: 30),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _NourReactionBubble(thinking: _nourThinking, text: _nourReaction),
                                ),
                              ],
                            ),
                          ),

                        if (hasVoiceNote && habits != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.25)),
                                boxShadow: [BoxShadow(color: AppTheme.primaryPink.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primaryPink.withValues(alpha: 0.1),
                                    child: const Icon(Icons.mic_rounded, color: AppTheme.primaryPink),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text("Voice Note", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                                  ),
                                  IconButton(
                                    icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: AppTheme.primaryPink, size: 34),
                                    onPressed: () => _togglePlayback(habits.audioPath),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                    onPressed: () => _deleteVoiceNote(habits.audioPath),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (habits != null && habits.imagePath != null && habits.imagePath!.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Stack(
                            children: [
                              Transform.rotate(
                                angle: -0.02,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(2, 4))],
                                  ),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.file(File(habits.imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text("Memory ✨", style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -5,
                                right: -5,
                                child: IconButton(
                                  onPressed: () => ref.read(habitNotifierProvider.notifier).updateImage(''),
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: stickerOptions.map((sticker) => GestureDetector(
                        onTap: () => _addSticker(sticker),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.primaryPink.withValues(alpha: 0.08), shape: BoxShape.circle),
                          child: Text(sticker, style: const TextStyle(fontSize: 20)),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 6)),

                IconButton(
                  icon: const Icon(Icons.headphones_outlined, color: AppTheme.textLight),
                  onPressed: widget.onPlayNextAsmr,
                  tooltip: "Change Ambiance",
                ),
                IconButton(
                  icon: const Icon(Icons.hourglass_bottom_rounded, color: AppTheme.textLight),
                  onPressed: _pickUnlockDate,
                  tooltip: "Time Capsule",
                ),
                IconButton(
                  icon: Icon(Icons.auto_fix_high_rounded, color: _isMagicInkActive ? AppTheme.primaryPink : AppTheme.textLight),
                  onPressed: () => setState(() => _isMagicInkActive = !_isMagicInkActive),
                  tooltip: "Magic Ink",
                ),
                IconButton(
                  icon: const Icon(Icons.draw_rounded, color: AppTheme.textLight),
                  onPressed: _openDoodleBoard,
                  tooltip: "Draw",
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library_rounded, color: AppTheme.textLight),
                  onPressed: _pickImage,
                  tooltip: "Photo",
                ),
                GestureDetector(
                  onTap: _toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _isRecording
                          ? const LinearGradient(colors: [Colors.redAccent, Colors.red])
                          : LinearGradient(colors: [AppTheme.primaryPink, AppTheme.primaryPink.withValues(alpha: 0.8)]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : AppTheme.primaryPink).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        )
      ],
    );
  }
}

class _NourReactionBubble extends StatelessWidget {
  final bool thinking;
  final String? text;
  const _NourReactionBubble({required this.thinking, required this.text});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Container(
        key: ValueKey(thinking ? 'thinking' : text),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            topLeft: Radius.circular(2), 
          ),
          border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.4), width: 1.2),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryPink.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(2, 4))
          ]
        ),
        child: thinking
            ? Text(
                "Nour is reading your page...",
                style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppTheme.textLight.withValues(alpha: 0.7)),
              )
            : Text(
                text ?? '',
                style: const TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: AppTheme.textDark, height: 1.4),
              ),
      ),
    );
  }
}

class _OnThisDayBanner extends StatelessWidget {
  final String text;
  final int yearsAgo;
  const _OnThisDayBanner({required this.text, required this.yearsAgo});

  @override
  Widget build(BuildContext context) {
    final snippet = text.length > 90 ? '${text.substring(0, 90)}...' : text;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFFFE9A8).withValues(alpha: 0.5), const Color(0xFFFFD4DC).withValues(alpha: 0.4)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD89A).withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🕰️", style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  yearsAgo == 1 ? "1 year ago, you wrote..." : "$yearsAgo years ago, you wrote...",
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  '"$snippet"',
                  style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppTheme.textDark.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotebookPainter extends CustomPainter {
  final double lineHeight;
  final int themeIndex;
  final Color moodTint;
  final DateTime currentDate;
  final double headerHeight;

  NotebookPainter({
    required this.lineHeight, 
    required this.themeIndex, 
    this.moodTint = AppTheme.primaryPink, 
    required this.currentDate,
    required this.headerHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paperPaint = Paint()..color = moodTint.withValues(alpha: 0.04);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paperPaint);

    if (themeIndex == 0 || themeIndex == 1) {
      final lineColor = themeIndex == 0 ? Colors.lightBlue.withValues(alpha: 0.3) : Colors.pink.withValues(alpha: 0.15);
      final linePaint = Paint()..color = lineColor..strokeWidth = 1.2;

      for (double y = headerHeight; y < size.height; y += lineHeight) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }

      final marginPaint = Paint()..color = moodTint.withValues(alpha: 0.40)..strokeWidth = 1.5;
      canvas.drawLine(Offset(70, 0), Offset(70, size.height), marginPaint);
      canvas.drawLine(Offset(74, 0), Offset(74, size.height), marginPaint);
      
    } else if (themeIndex == 2) {
      final gridPaint = Paint()..color = Colors.black.withValues(alpha: 0.04)..strokeWidth = 1.0;
      
      for (double x = 0; x < size.width; x += 20.0) {
        canvas.drawLine(Offset(x, headerHeight), Offset(x, size.height), gridPaint);
      }
      for (double y = headerHeight; y < size.height; y += 20.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
      
      final marginPaint = Paint()..color = moodTint.withValues(alpha: 0.30)..strokeWidth = 1.5;
      canvas.drawLine(Offset(70, 0), Offset(70, size.height), marginPaint);
    }

    final washPaint = Paint()
      ..shader = RadialGradient(
        colors: [moodTint.withValues(alpha: 0.06), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.85, 60), radius: 160));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 220), washPaint);
  }

  @override
  bool shouldRepaint(covariant NotebookPainter oldDelegate) => 
      oldDelegate.themeIndex != themeIndex || oldDelegate.moodTint != moodTint || oldDelegate.currentDate != currentDate || oldDelegate.headerHeight != headerHeight;
}