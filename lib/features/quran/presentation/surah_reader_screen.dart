import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // ✨ Offline DB ke liye import
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import '../data/surah_data.dart';
import 'quran_provider.dart';

// ✨ SMART CACHE API FETCHER (Offline Support ke sath)
final surahDetailProvider = FutureProvider.family<List<Map<String, String>>, int>((ref, surahId) async {
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'surah_offline_$surahId'; 

  // ✨ STEP 1: Pehle check karo ki kya data phone mein already save hai?
  final cachedData = prefs.getString(cacheKey);
  
  if (cachedData != null) {
    debugPrint("📂 Loading Surah $surahId from OFFLINE MEMORY");
    final List<dynamic> decodedData = json.decode(cachedData);
    return decodedData.map((e) => Map<String, String>.from(e)).toList();
  }

  // ✨ STEP 2: Agar save nahi hai, tabhi API call karo
  debugPrint("🌐 Fetching Surah $surahId from INTERNET");
  final url = Uri.parse('http://api.alquran.cloud/v1/surah/$surahId/editions/quran-uthmani,fr.hamidullah,ar.alafasy');
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final arabicAyahs = data['data'][0]['ayahs'];
    final frenchAyahs = data['data'][1]['ayahs'];
    final audioAyahs = data['data'][2]['ayahs'];

    List<Map<String, String>> result = [];
    for (int i = 0; i < arabicAyahs.length; i++) {
      result.add({
        'arabic': arabicAyahs[i]['text'],
        'french': frenchAyahs[i]['text'],
        'number': arabicAyahs[i]['numberInSurah'].toString(),
        'audio': audioAyahs[i]['audio'], 
      });
    }

    // ✨ STEP 3: API se data aane ke baad usko hamesha ke liye phone mein Save kar do
    await prefs.setString(cacheKey, json.encode(result));
    debugPrint("💾 Surah $surahId SAVED OFFLINE successfully!");

    return result;
  } else {
    throw Exception('Failed to load Surah');
  }
});

class SurahReaderScreen extends ConsumerWidget {
  final SurahInfo surahInfo;

  const SurahReaderScreen({super.key, required this.surahInfo});

  void _showFontSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text('Taille du Texte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 10),
              Consumer(
                builder: (context, ref, child) {
                  final fontScale = ref.watch(quranFontSizeProvider);
                  return Row(
                    children: [
                      const Text('A', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
                      Expanded(
                        child: Slider(
                          value: fontScale, min: 0.8, max: 2.0,
                          activeColor: AppTheme.primaryPink, inactiveColor: AppTheme.primaryPink.withOpacity(0.2),
                          onChanged: (value) => ref.read(quranFontSizeProvider.notifier).state = value,
                        ),
                      ),
                      const Text('A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahDetailProvider(surahInfo.id));
    final fontScale = ref.watch(quranFontSizeProvider);
    
    // ✨ Kaunsi audio chal rahi hai, wo check kar rahe hain
    final playingAudioUrl = ref.watch(audioStateProvider);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textDark),
            onPressed: () {
              // ✨ Agar user back jaye, toh audio ruk jani chahiye
              ref.read(audioStateProvider.notifier).togglePlay(""); 
              Navigator.pop(context);
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(surahInfo.nameFrench, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 20)),
              Text('${surahInfo.revelationType} • ${surahInfo.ayahCount} Versets', style: const TextStyle(fontSize: 12, color: AppTheme.primaryPink, fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Text('Aa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              onPressed: () => _showFontSettings(context, ref),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: surahAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryPink)),
          error: (err, stack) => Center(child: Text('Erreur de connexion. 🌸\n$err', textAlign: TextAlign.center)),
          data: (ayahs) {
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
              itemCount: ayahs.length,
              itemBuilder: (context, index) {
                final ayah = ayahs[index];
                
                // ✨ Check if this specific Ayah is currently playing
                final isPlayingThis = playingAudioUrl == ayah['audio'];
                
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  opacity: isPlayingThis ? 0.9 : 0.65, // ✨ Jo play ho raha hai wo thoda bright ho jayega
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPink.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Verset ${ayah['number']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryPink, fontSize: 12),
                            ),
                          ),
                          Row(
                            children: [
                              // ✨ Play/Pause Button (Écouter)
                              IconButton(
                                icon: Icon(
                                  isPlayingThis ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, 
                                  size: 28, 
                                  color: AppTheme.primaryPink
                                ),
                                onPressed: () {
                                  ref.read(audioStateProvider.notifier).togglePlay(ayah['audio']!);
                                },
                              ),
                              // Bookmark Button
                              IconButton(
                                icon: Icon(Icons.bookmark_border_rounded, size: 22, color: AppTheme.textDark.withOpacity(0.5)),
                                onPressed: () {
                                  ref.read(lastReadProvider.notifier).updateLastRead(
                                    surahId: surahInfo.id, arabic: surahInfo.nameArabic, french: surahInfo.nameFrench, ayah: int.parse(ayah['number']!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Position sauvegardée ✨'), backgroundColor: AppTheme.primaryPink, duration: Duration(seconds: 1),
                                  ));
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        ayah['arabic']!, textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 26 * fontScale, fontWeight: FontWeight.bold, color: AppTheme.textDark, fontFamily: 'serif', height: 1.6),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.black12, thickness: 1),
                      ),
                      Text(
                        ayah['french']!, textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 15 * fontScale, fontWeight: FontWeight.w500, color: AppTheme.textDark.withOpacity(0.8), fontStyle: FontStyle.italic, height: 1.5),
                      ),
                    ],
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