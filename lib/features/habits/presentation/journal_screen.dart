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
import '../../../core/theme/app_theme.dart';
import '../presentation/habit_provider.dart';
import '../../mood/presentation/mood_provider.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final TextEditingController _gratitudeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final LocalAuthentication auth = LocalAuthentication();

  bool _isLocked = true;
  bool _authFailed = false;
  int _currentThemeIndex = 0;

  // Audio (voice note) states
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;

  // ASMR ambience states
  final AudioPlayer _asmrPlayer = AudioPlayer();
  int _asmrIndex = 0; // 0: Off, 1: Rain, 2: Night, 3: Cafe
  final List<String> asmrNames = [
    "Off",
    "Pluie Douce 🌧️",
    "Nuit Paisible 🌙",
    "Café Marocain ☕"
  ];
  final List<String> asmrFiles = [
    "",
    "audio/rain.mp3",
    "audio/night.mp3",
    "audio/cafe.mp3",
  ];

  // Doodle controller
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 4,
    penColor: AppTheme.primaryPink,
    exportBackgroundColor: Colors.white,
  );

  // Magic ink reveal
  bool _isMagicInkActive = false;
  bool _isTextRevealed = false;

  final List<String> dailyPrompts = [
    "Qu'est-ce qui t'a fait sourire aujourd'hui ? ✨",
    "De quoi es-tu reconnaissante aujourd'hui ? 🌸",
    "Quelle a été la meilleure partie de ta journée ? 💖",
    "Comment as-tu pris soin de toi aujourd'hui ? 💧",
  ];

  final List<String> stickerOptions = ['🌸', '💖', '✨', '☕', '🦋', '📖', '🤲'];

  @override
  void initState() {
    super.initState();
    _authenticate();
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _gratitudeController.dispose();
    _signatureController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _asmrPlayer.stop();
    _asmrPlayer.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Déverrouiller ton journal intime 🔐',
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

  // ✨ TIME CAPSULE LOGIC ✨
  Future<void> _pickUnlockDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryPink,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
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
          content: Text("⏳ Capsule scellée jusqu'au $formattedDate !"),
          backgroundColor: AppTheme.textDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    }
  }

  // ✨ ASMR TOGGLE — NOW ACTUALLY PLAYS AUDIO ✨
  Future<void> _toggleAsmr() async {
    final newIndex = (_asmrIndex + 1) % asmrNames.length;

    try {
      if (newIndex == 0) {
        await _asmrPlayer.stop();
      } else {
        await _asmrPlayer.stop();
        await _asmrPlayer.setReleaseMode(ReleaseMode.loop);
        await _asmrPlayer.play(AssetSource(asmrFiles[newIndex]));
      }
      setState(() => _asmrIndex = newIndex);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            newIndex == 0 ? "Ambiance désactivée 🔇" : "Lecture: ${asmrNames[newIndex]}",
          ),
          backgroundColor: AppTheme.primaryPink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } catch (e) {
      debugPrint("ASMR play error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Fichier audio manquant pour ${asmrNames[newIndex]} 🎵"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(habitNotifierProvider.notifier).updateImage(image.path);
    }
  }

  void _addSticker(String sticker) {
    _gratitudeController.text = '${_gratitudeController.text} $sticker';
    _gratitudeController.selection =
        TextSelection.collapsed(offset: _gratitudeController.text.length);
    ref.read(habitNotifierProvider.notifier).updateGratitude(_gratitudeController.text);
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
        });
        if (path != null) {
          ref.read(habitNotifierProvider.notifier).updateAudio(path);
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final String path =
              '${dir.path}/journal_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
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

  // ✨ NEW: DELETE VOICE NOTE ✨
  Future<void> _deleteVoiceNote(String? dbAudioPath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Supprimer la note vocale ? 🎙️",
            style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        content: const Text("Cette action est irréversible.",
            style: TextStyle(color: AppTheme.textLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler", style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _audioPlayer.stop();

      // try to delete the actual file from disk
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Note vocale supprimée 🗑️"),
          backgroundColor: AppTheme.textDark,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _openDoodleBoard() {
    _signatureController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Dessine tes pensées 🎨",
            style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
            child: Signature(
                controller: _signatureController, height: 300, backgroundColor: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _signatureController.clear(),
            child: const Text("Effacer", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_signatureController.isNotEmpty) {
                final Uint8List? data = await _signatureController.toPngBytes();
                if (data != null) {
                  final dir = await getApplicationDocumentsDirectory();
                  final File file =
                      File('${dir.path}/doodle_${DateTime.now().millisecondsSinceEpoch}.png');
                  await file.writeAsBytes(data);
                  ref.read(habitNotifierProvider.notifier).updateImage(file.path);
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child:
                const Text("Sauvegarder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _saveAndShowAffirmation(String? moodType) {
    String affirmation = "Chaque jour est un nouveau départ. Tu fais de l'excellent travail. ✨";
    if (moodType == "Sad") {
      affirmation =
          "C'est normal de ne pas être parfaite tous les jours. Respire profondément, Habibati. Demain sera plus doux. 🌧️💖";
    } else if (moodType == "Stressed") {
      affirmation = "Relâche tes épaules. Ferme les yeux une seconde. Tu as le droit de te reposer. 🍃✨";
    } else if (moodType == "Happy") {
      affirmation = "Garde ce sourire! Ta lumière illumine tout autour de toi. ☀️🌸";
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.primaryPink.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: AppTheme.primaryPink.withOpacity(0.15), blurRadius: 24, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: AppTheme.primaryPink, size: 48),
              const SizedBox(height: 24),
              Text(
                affirmation,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'serif',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.textDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Fermer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (_currentThemeIndex == 0) return const Color(0xFFFFFDF2);
    if (_currentThemeIndex == 1) return const Color(0xFFFFF0F5);
    return const Color(0xFFF6F8FF);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
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
                    color: AppTheme.primaryPink.withOpacity(0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryPink.withOpacity(0.15), blurRadius: 24, spreadRadius: 6),
                    ],
                  ),
                  child: const Icon(Icons.lock_rounded, size: 64, color: AppTheme.primaryPink),
                ),
                const SizedBox(height: 28),
                const Text("Journal Protégé 💗",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Text(
                  _authFailed ? "Authentification échouée, réessaie ✨" : "Tes pensées, en sécurité",
                  style: TextStyle(fontSize: 13, color: AppTheme.textLight.withOpacity(0.8)),
                ),
                const SizedBox(height: 36),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPink,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 6,
                    shadowColor: AppTheme.primaryPink.withOpacity(0.5),
                  ),
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint_rounded, color: Colors.white),
                  label: const Text("Déverrouiller", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
          ),
        ),
      );
    }

    final habits = ref.watch(habitNotifierProvider);
    final currentMood = ref.watch(moodNotifierProvider);
    final String todayPrompt = dailyPrompts[DateTime.now().day % dailyPrompts.length];

    if (habits != null && _gratitudeController.text != habits.gratitudeText) {
      _gratitudeController.text = habits.gratitudeText;
      _gratitudeController.selection = TextSelection.collapsed(offset: _gratitudeController.text.length);
    }

    String vibeText = "Vibe du jour: Paisible 🍃";
    if (currentMood?.moodType == "Happy") vibeText = "Vibe du jour: Rayonnante ☀️";
    if (currentMood?.moodType == "Tired") vibeText = "Vibe du jour: Épuisée ☕";
    if (currentMood?.moodType == "Sad") vibeText = "Vibe du jour: Nuageuse 🌧️";
    if (currentMood?.moodType == "Stressed") vibeText = "Vibe du jour: Tendue 🌪️";

    bool applyBlur = _isMagicInkActive && !_isTextRevealed;
    final hasVoiceNote = habits?.audioPath != null && habits!.audioPath!.isNotEmpty || _recordedFilePath != null;

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textDark),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              DateFormat('EEEE', 'fr_FR').format(DateTime.now()),
              style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w600, color: AppTheme.primaryPink, fontSize: 12),
            ),
            Text(
              "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
              style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _asmrIndex == 0 ? Colors.white.withOpacity(0.6) : AppTheme.primaryPink.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_asmrIndex == 0 ? Icons.headphones_outlined : Icons.headphones,
                  size: 18, color: _asmrIndex == 0 ? AppTheme.textDark : AppTheme.primaryPink),
            ),
            onPressed: _toggleAsmr,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle),
              child: const Icon(Icons.palette_outlined, size: 18, color: AppTheme.textDark),
            ),
            onPressed: () => setState(() => _currentThemeIndex = (_currentThemeIndex + 1) % 3),
          ),
          TextButton(
            onPressed: () => _saveAndShowAffirmation(currentMood?.moodType),
            child: const Text("Terminer 💗", style: TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
      body: habits == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPink))
          : Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: NotebookPainter(lineHeight: 32.0, themeIndex: _currentThemeIndex))),
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 70, bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (habits.unlockDate != null && habits.unlockDate!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 65, right: 20, bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [AppTheme.textDark, AppTheme.textDark.withOpacity(0.85)]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: AppTheme.textDark.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.hourglass_bottom_rounded, color: AppTheme.primaryPink, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text("Capsule scellée jusqu'au ${habits.unlockDate}",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Vibe tag + ASMR chip
                        Padding(
                          padding: const EdgeInsets.only(left: 65, right: 20, bottom: 10),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.primaryPink.withOpacity(0.2)),
                                ),
                                child: Text(vibeText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
                              ),
                              if (_asmrIndex != 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryPink.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.music_note_rounded, size: 12, color: AppTheme.primaryPink),
                                      const SizedBox(width: 4),
                                      Text(asmrNames[_asmrIndex],
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPink)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(left: 65, right: 20, bottom: 10),
                          child: Text(todayPrompt,
                              style: const TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, fontSize: 14)),
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
                              onChanged: (text) => ref.read(habitNotifierProvider.notifier).updateGratitude(text),
                              style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50), fontFamily: 'serif', fontWeight: FontWeight.w600, height: 32.0 / 16.0),
                              decoration: InputDecoration(
                                hintText: "Cher journal...",
                                hintStyle: TextStyle(color: AppTheme.textDark.withOpacity(0.3), fontStyle: FontStyle.italic),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.only(left: 65, right: 20),
                              ),
                            ),
                          ),
                        ),

                        if (applyBlur)
                          Padding(
                            padding: const EdgeInsets.only(left: 65, right: 20, top: 4),
                            child: Text("👀 Maintiens pour révéler ton texte secret",
                                style: TextStyle(fontSize: 11, color: AppTheme.textLight.withOpacity(0.7), fontStyle: FontStyle.italic)),
                          ),

                        if (hasVoiceNote)
                          Padding(
                            padding: const EdgeInsets.only(left: 65, right: 20, top: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primaryPink.withOpacity(0.25)),
                                boxShadow: [BoxShadow(color: AppTheme.primaryPink.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
                                    child: const Icon(Icons.mic_rounded, color: AppTheme.primaryPink),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text("Note Vocale", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
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

                        if (habits.imagePath != null && habits.imagePath!.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.only(left: 65, right: 20),
                            child: Stack(
                              children: [
                                Transform.rotate(
                                  angle: -0.02,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(2, 4))],
                                    ),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.file(File(habits.imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text("Souvenir ✨", style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, color: Colors.black54)),
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
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ✨ BOTTOM TOOLBAR ✨
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: SafeArea(
                      top: false,
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
                                    decoration: BoxDecoration(color: AppTheme.primaryPink.withOpacity(0.08), shape: BoxShape.circle),
                                    child: Text(sticker, style: const TextStyle(fontSize: 20)),
                                  ),
                                )).toList(),
                              ),
                            ),
                          ),
                          Container(width: 1, height: 28, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 6)),
                          IconButton(
                            icon: const Icon(Icons.hourglass_bottom_rounded, color: AppTheme.textLight),
                            onPressed: _pickUnlockDate,
                            tooltip: "Capsule temporelle",
                          ),
                          IconButton(
                            icon: Icon(Icons.auto_fix_high_rounded, color: _isMagicInkActive ? AppTheme.primaryPink : AppTheme.textLight),
                            onPressed: () => setState(() => _isMagicInkActive = !_isMagicInkActive),
                            tooltip: "Encre magique",
                          ),
                          IconButton(
                            icon: const Icon(Icons.draw_rounded, color: AppTheme.textLight),
                            onPressed: _openDoodleBoard,
                            tooltip: "Dessiner",
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
                                    : LinearGradient(colors: [AppTheme.primaryPink, AppTheme.primaryPink.withOpacity(0.8)]),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? Colors.red : AppTheme.primaryPink).withOpacity(0.4),
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
                  ),
                )
              ],
            ),
    );
  }
}

class NotebookPainter extends CustomPainter {
  final double lineHeight;
  final int themeIndex;
  NotebookPainter({required this.lineHeight, required this.themeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (themeIndex == 0 || themeIndex == 1) {
      final lineColor = themeIndex == 0 ? Colors.lightBlue.withOpacity(0.2) : Colors.pink.withOpacity(0.08);
      final linePaint = Paint()..color = lineColor..strokeWidth = 1.0;
      for (double y = 100.0; y < size.height; y += lineHeight) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
      final marginPaint = Paint()..color = Colors.redAccent.withOpacity(0.25)..strokeWidth = 1.5;
      canvas.drawLine(Offset(50, 0), Offset(50, size.height), marginPaint);
      canvas.drawLine(Offset(54, 0), Offset(54, size.height), marginPaint);
    } else if (themeIndex == 2) {
      final gridPaint = Paint()..color = Colors.black.withOpacity(0.04)..strokeWidth = 1.0;
      for (double x = 0; x < size.width; x += 20.0) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += 20.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
      final marginPaint = Paint()..color = Colors.redAccent.withOpacity(0.25)..strokeWidth = 1.5;
      canvas.drawLine(Offset(50, 0), Offset(50, size.height), marginPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}