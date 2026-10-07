import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import '../../../core/providers/neki_provider.dart'; // ✨ NEKI PROVIDER IMPORT

class EmotionDuasScreen extends StatefulWidget {
  const EmotionDuasScreen({super.key});

  @override
  State<EmotionDuasScreen> createState() => _EmotionDuasScreenState();
}

class _EmotionDuasScreenState extends State<EmotionDuasScreen> {
  int _selectedTabIndex = 0; 
  
  List<dynamic> _emotionsList = [];
  List<dynamic> _dailyLifeList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSmartDuas();
  }

  // ✨ JSON READ KAREGA AUR SHUFFLE KAREGA
  Future<void> _loadSmartDuas() async {
    try {
      final String response = await rootBundle.loadString('assets/data/all_duas.json');
      final data = await json.decode(response);
      List<dynamic> allDuas = data['duas'];

      List<dynamic> emotions = allDuas.where((d) => d['category'] == 'Emotions').toList();
      List<dynamic> daily = allDuas.where((d) => d['category'] == 'Daily Life').toList();

      emotions.shuffle();
      daily.shuffle();

      setState(() {
        _emotionsList = emotions;
        _dailyLifeList = daily;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ JSON Load Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showDuaBottomSheet(BuildContext context, Map<String, dynamic> dua) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DuaBottomSheetContent(dua: dua),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _selectedTabIndex == 0 ? _emotionsList : _dailyLifeList;

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
            'Daily Duas',
            style: AppTextStyles.displayMedium.copyWith(fontSize: 22),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.1)),
                ),
                child: CupertinoSlidingSegmentedControl<int>(
                  backgroundColor: Colors.transparent,
                  thumbColor: AppColors.gold.withValues(alpha: 0.2),
                  groupValue: _selectedTabIndex,
                  padding: const EdgeInsets.all(4),
                  children: {
                    0: _buildTabContent("Emotions", 0),
                    1: _buildTabContent("Daily Life", 1),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTabIndex = value;
                      });
                    }
                  },
                ),
              ),
            ),
            
            Expanded(
              child: Stack(
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
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  else if (currentList.isEmpty)
                    Center(
                      child: Text(
                        "No duas found! Please check all_duas.json", 
                        style: TextStyle(color: AppColors.textMuted)
                      )
                    )
                  else
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      physics: const BouncingScrollPhysics(),
                      itemCount: currentList.length,
                      itemBuilder: (context, index) {
                        final dua = currentList[index];
                        final icon = dua['emoji'] ?? dua['icon'] ?? '✨';
                        final titleText = dua['title'] ?? dua['emotion'] ?? 'Dua';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () => _showDuaBottomSheet(context, dua),
                            borderRadius: BorderRadius.circular(20),
                            child: GlassCard(
                              opacity: 0.6,
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      titleText,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Icon(CupertinoIcons.chevron_right, color: AppColors.gold, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? AppColors.gold : AppColors.textMuted,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ✨ STATEFUL BOTTOM SHEET WITH RIVERPOD (NEKI SYSTEM)
class _DuaBottomSheetContent extends ConsumerStatefulWidget {
  final Map<String, dynamic> dua; 
  const _DuaBottomSheetContent({required this.dua});

  @override
  ConsumerState<_DuaBottomSheetContent> createState() => _DuaBottomSheetContentState();
}

class _DuaBottomSheetContentState extends ConsumerState<_DuaBottomSheetContent> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _hasEarnedNeki = false; 

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleAudio() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      try {
        String url = "https://translate.google.com/translate_tts?ie=UTF-8&tl=ar&client=tw-ob&q=${Uri.encodeComponent(widget.dua['arabic']!)}";
        await _audioPlayer.play(UrlSource(url));
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlaying = false);
        });
      } catch (e) {
        if (mounted) setState(() => _isPlaying = false);
      }
    }
  }

  // ✨ YAHAN SE USER NEKI EARN KAREGA
  void _claimNeki() {
    if (!_hasEarnedNeki) {
      HapticFeedback.heavyImpact(); 
      
      ref.read(nekiProvider.notifier).addNekis(10);
      
      setState(() {
        _hasEarnedNeki = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text("✨", style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              const Text(
                "+10 Neki Added to your Profile!",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.background),
              ),
            ],
          ),
          backgroundColor: AppColors.gold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          duration: const Duration(seconds: 2),
        ),
      );
      
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.dua['emoji'] ?? widget.dua['icon'] ?? '✨';
    final titleText = widget.dua['title'] ?? widget.dua['emotion'] ?? 'Dua';
    final reference = widget.dua['reference'] ?? 'Hisnul Muslim';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GlassCard(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        opacity: 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titleText,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayMedium.copyWith(fontSize: 20, color: AppColors.gold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              widget.dua['arabic'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.dua['transliteration'] ?? '',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.dua['meaning'] ?? '',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              "Reference: $reference",
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            
            // AUDIO BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPlaying ? AppColors.surfaceElevated : AppColors.background.withValues(alpha: 0.5),
                  foregroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5))
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: _toggleAudio,
                icon: Icon(_isPlaying ? CupertinoIcons.stop_fill : CupertinoIcons.play_arrow_solid),
                label: Text(
                  _isPlaying ? 'Stop Audio' : 'Listen to Dua',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 12),

            // ✨ NEKI CLAIM BUTTON 
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasEarnedNeki ? AppColors.surfaceElevated : AppColors.gold,
                  foregroundColor: _hasEarnedNeki ? AppColors.gold : AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: _hasEarnedNeki ? 0 : 4,
                ),
                onPressed: _hasEarnedNeki ? null : _claimNeki,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_hasEarnedNeki ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.heart_solid),
                    const SizedBox(width: 8),
                    Text(
                      _hasEarnedNeki ? 'Claimed +10 Neki' : 'Mark as Read & Earn Neki',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}