import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import '../data/surah_data.dart';
import 'quran_provider.dart';

class SurahParams {
  final int surahId;
  final String qari;
  final String translation;

  const SurahParams({
    required this.surahId,
    required this.qari,
    required this.translation,
  });

  @override
  bool operator ==(Object other) =>
      other is SurahParams &&
      other.surahId == surahId &&
      other.qari == qari &&
      other.translation == translation;

  @override
  int get hashCode => Object.hash(surahId, qari, translation);
}

final surahDetailProvider =
    FutureProvider.family<List<Map<String, String>>, SurahParams>(
        (ref, params) async {
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'surah_${params.surahId}_${params.qari}_${params.translation}';
  final cachedData = prefs.getString(cacheKey);

  if (cachedData != null) {
    final List<dynamic> decoded = json.decode(cachedData);
    return decoded.map((e) => Map<String, String>.from(e)).toList();
  }

  // FIX: http -> https (release build me http block hota hai)
  final url = Uri.parse(
    'https://api.alquran.cloud/v1/surah/${params.surahId}'
    '/editions/quran-uthmani,${params.translation},${params.qari}',
  );

  final response = await http.get(url).timeout(const Duration(seconds: 15));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final arabicAyahs = data['data'][0]['ayahs'];
    final translationAyahs = data['data'][1]['ayahs'];
    final audioAyahs = data['data'][2]['ayahs'];

    List<Map<String, String>> result = [];
    for (int i = 0; i < arabicAyahs.length; i++) {
      result.add({
        'arabic': arabicAyahs[i]['text'],
        'translation': translationAyahs[i]['text'],
        'number': arabicAyahs[i]['numberInSurah'].toString(),
        'audio': audioAyahs[i]['audio'],
      });
    }

    await prefs.setString(cacheKey, json.encode(result));
    return result;
  } else {
    throw Exception('API Error: ${response.statusCode}');
  }
});

class SurahReaderScreen extends ConsumerStatefulWidget {
  final SurahInfo surahInfo;
  const SurahReaderScreen({super.key, required this.surahInfo});

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isPlayingFullSurah = false;
  final Map<int, GlobalKey> _ayahKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SettingsSheet(
        onStop: () {
          ref.read(audioStateProvider.notifier).stop();
          setState(() => _isPlayingFullSurah = false);
        },
      ),
    );
  }

  // Unified Play Function
  Future<void> _playFromIndex(int index, List<Map<String, String>> ayahs) async {
    final audioNotifier = ref.read(audioStateProvider.notifier);
    await audioNotifier.stop();
    setState(() => _isPlayingFullSurah = true);

    final mode = ref.read(audioPlaybackModeProvider);

    if (mode == AudioPlaybackMode.arabic) {
      final urls = ayahs.map((a) => a['audio'].toString()).toList();
      final arabicTexts = ayahs.map((a) => a['arabic'].toString()).toList();
      // arabicTexts dene se word-by-word glow chalta hai
      audioNotifier.startPlaylist(
        urls,
        startIndex: index,
        arabicTexts: arabicTexts,
      );
    } else {
      final currentTranslation = ref.read(selectedTranslationProvider);
      final audioEditionId = translationAudioMap[currentTranslation];

      if (audioEditionId == null) {
        setState(() => _isPlayingFullSurah = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio translation not available.')));
        return;
      }

      try {
        // FIX: http -> https
        final url = Uri.parse('https://api.alquran.cloud/v1/surah/${widget.surahInfo.id}/$audioEditionId');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final fetchedAyahs = data['data']['ayahs'] as List;
          final urls = fetchedAyahs.map((a) => a['audio'].toString()).toList();
          // Translation audio me arabic words nahi bolte, isliye word glow nahi
          audioNotifier.startPlaylist(urls, startIndex: index);
        } else {
          throw Exception('API failed');
        }
      } catch (e) {
        setState(() => _isPlayingFullSurah = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load translation audio.')));
      }
    }
  }

  void _togglePlayPause(List<Map<String, String>> ayahs) {
    if (_isPlayingFullSurah) {
      ref.read(audioStateProvider.notifier).stop();
      setState(() => _isPlayingFullSurah = false);
    } else {
      _playFromIndex(0, ayahs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qari = ref.watch(selectedQariProvider);
    final translation = ref.watch(selectedTranslationProvider);

    final surahAsync = ref.watch(surahDetailProvider(SurahParams(
      surahId: widget.surahInfo.id,
      qari: qari,
      translation: translation,
    )));

    final fontScale = ref.watch(quranFontSizeProvider);
    final currentAyahIndex = ref.watch(currentAyahIndexProvider);

    // Audio khatam hone par button reset
    ref.listen<String?>(audioStateProvider, (previous, current) {
      if (current == null && _isPlayingFullSurah) {
        setState(() => _isPlayingFullSurah = false);
      }
    });

    // Smart Auto Scroll Listener (ayah badalne par)
    ref.listen<int>(currentAyahIndexProvider, (previous, currentIndex) async {
      if (currentIndex != -1) {
        final key = _ayahKeys[currentIndex];
        if (key != null) {
          if (key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              alignment: 0.2,
            );
          } else {
            if (_scrollController.hasClients) {
              double estimatedOffset = currentIndex * 140.0;
              await _scrollController.animateTo(
                estimatedOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
              await Future.delayed(const Duration(milliseconds: 100));
              if (key.currentContext != null) {
                Scrollable.ensureVisible(
                  key.currentContext!,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  alignment: 0.2,
                );
              }
            }
          }
        }
      }
    });

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.gold),
            onPressed: () {
              ref.read(audioStateProvider.notifier).stop();
              Navigator.pop(context);
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.surahInfo.nameFrench,
                style: AppTextStyles.bodyLarge.copyWith(fontSize: 18),
              ),
              Text(
                '${widget.surahInfo.revelationType} • ${widget.surahInfo.ayahCount} Verses',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            surahAsync.when(
              data: (ayahs) => IconButton(
                icon: Icon(
                  _isPlayingFullSurah ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: AppColors.gold,
                  size: 30,
                ),
                onPressed: () => _togglePlayPause(ayahs),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            IconButton(
              icon: Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 26),
              onPressed: () => _showSettingsSheet(context),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: surahAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: AppColors.gold)),
          error: (err, stack) => Center(child: Text('Error loading Surah', style: TextStyle(color: AppColors.gold))),
          data: (ayahs) {
            return ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
              itemCount: ayahs.length,
              itemBuilder: (context, index) {
                final ayah = ayahs[index];
                final isPlayingThis = currentAyahIndex == index;

                _ayahKeys.putIfAbsent(index, () => GlobalKey());

                return Container(
                  key: _ayahKeys[index],
                  child: _AyahTile(
                    ayah: ayah,
                    fontScale: fontScale,
                    isPlaying: isPlayingThis,
                    surahInfo: widget.surahInfo,
                    onPlayTap: () => _playFromIndex(index, ayahs),
                    onBookmark: () {
                      ref.read(lastReadProvider.notifier).updateLastRead(
                            surahId: widget.surahInfo.id,
                            arabic: widget.surahInfo.nameArabic,
                            french: widget.surahInfo.nameFrench,
                            ayah: int.parse(ayah['number']!),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Position saved ✨'),
                        backgroundColor: AppColors.surfaceElevated,
                        duration: const Duration(seconds: 1),
                      ));
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─── Compact Ayah Tile (word-by-word glow ke saath) ───────────────
class _AyahTile extends ConsumerWidget {
  final Map<String, String> ayah;
  final double fontScale;
  final bool isPlaying;
  final SurahInfo surahInfo;
  final VoidCallback onPlayTap;
  final VoidCallback onBookmark;

  const _AyahTile({
    required this.ayah,
    required this.fontScale,
    required this.isPlaying,
    required this.surahInfo,
    required this.onPlayTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sirf jo ayah chal rahi hai wahi word index sunti hai (baaki rebuild nahi hote)
    final int activeWord = isPlaying ? ref.watch(currentWordIndexProvider) : -1;
    final bool wordMode = isPlaying && activeWord >= 0;

    final words = splitAyahWords(ayah['arabic']!);

    final baseStyle = GoogleFonts.amiri(
      fontSize: 24 * fontScale,
      fontWeight: FontWeight.bold,
      // word mode me default rang safed; padhe hue words gold ho jate hain
      color: isPlaying && !wordMode ? AppColors.gold : AppColors.textPrimary,
      height: 1.8,
    );

    final spans = <InlineSpan>[];
    for (int i = 0; i < words.length; i++) {
      TextStyle? style;
      if (wordMode) {
        if (i == activeWord) {
          // Abhi ye lafz bola ja raha hai: glow
          style = TextStyle(
            color: AppColors.gold,
            backgroundColor: AppColors.gold.withOpacity(0.18),
            shadows: [
              Shadow(color: AppColors.gold.withOpacity(0.95), blurRadius: 14),
            ],
          );
        } else if (i < activeWord) {
          // Pehle padhe ja chuke words
          style = TextStyle(color: AppColors.gold.withOpacity(0.75));
        }
      }
      spans.add(TextSpan(text: words[i], style: style));
      if (i < words.length - 1) spans.add(const TextSpan(text: ' '));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
        border: isPlaying
            ? Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        opacity: isPlaying ? 0.85 : 0.35,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AyahBadge(number: ayah['number']!, isActive: isPlaying),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onPlayTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? AppColors.gold.withOpacity(0.15)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 22,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onBookmark,
                      child: Icon(
                        Icons.bookmark_border_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(children: spans),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: baseStyle,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                color: AppColors.gold.withOpacity(0.12),
                thickness: 0.8,
              ),
            ),
            Text(
              ayah['translation']!,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14 * fontScale,
                fontWeight: isPlaying ? FontWeight.w500 : FontWeight.w400,
                color: isPlaying ? Colors.white : AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Settings Bottom Sheet ────────────────────────────────────────
class _SettingsSheet extends ConsumerWidget {
  final VoidCallback onStop;
  const _SettingsSheet({required this.onStop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = ref.watch(quranFontSizeProvider);
    final currentQari = ref.watch(selectedQariProvider);
    final currentTranslation = ref.watch(selectedTranslationProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Listen To', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final currentMode = ref.watch(audioPlaybackModeProvider);
                return Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          onStop();
                          ref.read(audioPlaybackModeProvider.notifier).state = AudioPlaybackMode.arabic;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: currentMode == AudioPlaybackMode.arabic
                                ? AppColors.gold.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentMode == AudioPlaybackMode.arabic
                                  ? AppColors.gold
                                  : AppColors.textMuted.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text('🕌 Arabic Qari',
                                style: TextStyle(
                                  color: currentMode == AudioPlaybackMode.arabic ? AppColors.gold : AppColors.textSecondary,
                                  fontWeight: currentMode == AudioPlaybackMode.arabic ? FontWeight.bold : FontWeight.normal,
                                )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          onStop();
                          ref.read(audioPlaybackModeProvider.notifier).state = AudioPlaybackMode.translation;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: currentMode == AudioPlaybackMode.translation
                                ? AppColors.gold.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentMode == AudioPlaybackMode.translation
                                  ? AppColors.gold
                                  : AppColors.textMuted.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text('🎧 Translation',
                                style: TextStyle(
                                  color: currentMode == AudioPlaybackMode.translation ? AppColors.gold : AppColors.textSecondary,
                                  fontWeight: currentMode == AudioPlaybackMode.translation ? FontWeight.bold : FontWeight.normal,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            Text('Text Size', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('A',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.gold,
                      inactiveTrackColor: AppColors.gold.withOpacity(0.15),
                      thumbColor: AppColors.gold,
                      overlayColor: AppColors.gold.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: fontScale,
                      min: 0.8,
                      max: 2.0,
                      onChanged: (v) =>
                          ref.read(quranFontSizeProvider.notifier).state = v,
                    ),
                  ),
                ),
                Text('A',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 20),

            Text('Translation Language', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: translationEditions.map((lang) {
                final isSelected = currentTranslation == lang['id'];
                return GestureDetector(
                  onTap: () {
                    ref.read(selectedTranslationProvider.notifier).state = lang['id']!;
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withOpacity(0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.textMuted.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${lang['flag']} ${lang['name']}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.gold : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            Text('Reciter', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            ...qariList.map((qari) {
              final isSelected = currentQari == qari['id'];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  qari['name']!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.gold : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20)
                    : null,
                onTap: () {
                  onStop();
                  ref.read(selectedQariProvider.notifier).state = qari['id']!;
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AyahBadge extends StatelessWidget {
  final String number;
  final bool isActive;
  const _AyahBadge({required this.number, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.gold : AppColors.gold.withOpacity(0.5);
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(color: color.withOpacity(0.5), width: 1.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.4),
              color: AppColors.surfaceElevated.withOpacity(isActive ? 0.9 : 0.5),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}