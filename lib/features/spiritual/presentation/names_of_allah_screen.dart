import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart'; // ✨ NAYA: Animation Import

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import '../data/allah_names_data.dart'; 

class NamesOfAllahScreen extends StatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingIndex;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playNameAudio(int index, String arabicName) async {
    // Agar same audio play ho rahi hai toh stop kardo
    if (_playingIndex == index) {
      await _audioPlayer.stop();
      setState(() => _playingIndex = null);
      return;
    }

    setState(() => _playingIndex = index);

    try {
      // ✨ Google's free TTS URL trick to pronounce Arabic beautifully!
      String url = "https://translate.google.com/translate_tts?ie=UTF-8&tl=ar&client=tw-ob&q=${Uri.encodeComponent(arabicName)}";
      await _audioPlayer.play(UrlSource(url));
      
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingIndex = null);
      });
    } catch (e) {
      debugPrint("Audio Play Error: $e");
      if (mounted) setState(() => _playingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            '99 Names of Allah',
            style: AppTextStyles.displayMedium.copyWith(fontSize: 22),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/islamic_bg.png',
                  fit: BoxFit.cover,
                  color: Colors.black,
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
            
            GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemCount: allahNames.length,
              itemBuilder: (context, index) {
                final name = allahNames[index];
                return _buildNameCard(context, name, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameCard(BuildContext context, Map<String, String> name, int index) {
    bool isPlaying = _playingIndex == index;

    return InkWell(
      onTap: () => _playNameAudio(index, name["arabic"]!),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isPlaying
              ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)]
              : [],
        ),
        child: GlassCard(
          opacity: isPlaying ? 0.75 : 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    isPlaying ? CupertinoIcons.speaker_3_fill : CupertinoIcons.speaker_2,
                    color: isPlaying ? AppColors.gold : AppColors.textMuted.withValues(alpha: 0.5),
                    size: 18,
                  ),
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                name["arabic"]!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri', 
                  fontSize: 28,
                  color: isPlaying ? Colors.white : AppColors.gold,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name["transliteration"]!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPlaying ? AppColors.goldLight : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name["meaning"]!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    )
    // ✨ MAGIC ANIMATION ✨
    .animate(delay: (index * 50).ms) // Har card 50ms ke delay ke sath aayega
    .fadeIn(duration: 400.ms, curve: Curves.easeOut) // Halki si transparency se show hoga
    .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutCubic); // Halke se neeche se upar float hoga
  }
}