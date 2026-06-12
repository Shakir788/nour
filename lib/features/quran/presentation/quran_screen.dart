import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import '../data/surah_data.dart';
import 'quran_provider.dart';
import 'surah_reader_screen.dart';

// ✨ Naya Provider: Search Bar ka data track karne ke liye
final searchQueryProvider = StateProvider<String>((ref) => '');

class QuranScreen extends ConsumerWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRead = ref.watch(lastReadProvider);
    
    // ✨ Search Logic: User jo type karega us hisaab se Surahs filter hongi
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    final filteredSurahs = QuranData.surahs.where((surah) {
      return surah.nameFrench.toLowerCase().contains(searchQuery) ||
             surah.nameArabic.contains(searchQuery) ||
             surah.id.toString() == searchQuery; // Number se bhi search kar sakte hain
    }).toList();

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saint Coran 📖', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 22)),
              Text('Paix et Sérénité', style: TextStyle(fontSize: 12, color: AppTheme.primaryPink, fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            // ✨ Offline/Download Indicator Icon (Aesthetic detail)
            IconButton(
              icon: const Icon(Icons.cloud_done_rounded, color: AppTheme.primaryPink, size: 24),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Mode hors ligne activé 📴 (Offline mode active)'),
                  backgroundColor: AppTheme.primaryPink,
                ));
              },
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Column(
          children: [
            // 1. Dernière Lecture (Last Read Card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: GestureDetector(
                onTap: () {
                  if (lastRead != null) {
                    final surahInfo = QuranData.surahs.firstWhere((s) => s.id == lastRead.surahId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SurahReaderScreen(surahInfo: surahInfo),
                      ),
                    );
                  }
                },
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  opacity: 0.7,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryPink, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dernière Lecture',
                              style: TextStyle(fontSize: 13, color: AppTheme.primaryPink, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lastRead != null ? lastRead.surahNameFrench : 'Commencer la lecture',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                            ),
                            if (lastRead != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Verset ${lastRead.ayahNumber}',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textDark.withOpacity(0.6), fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (lastRead != null)
                        Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textDark.withOpacity(0.3), size: 18)
                    ],
                  ),
                ),
              ),
            ),

            // ✨ 2. Smart Search Bar (Recherche)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
              child: GlassCard(
                opacity: 0.5,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                  style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Rechercher une sourate...', // French for "Search a surah..."
                    hintStyle: TextStyle(color: AppTheme.textDark.withOpacity(0.4), fontSize: 15),
                    icon: const Icon(Icons.search_rounded, color: AppTheme.primaryPink),
                  ),
                ),
              ),
            ),

            // 3. Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 15, 28, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Index des Sourates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                  // ✨ Yahan total surahs ki jagah filtered count dikhega
                  Text('${filteredSurahs.length} Sourates', style: const TextStyle(fontSize: 13, color: AppTheme.primaryPink, fontWeight: FontWeight.w700)),
                ],
              ),
            ),

            // 4. Surah List (Filtered)
            Expanded(
              child: filteredSurahs.isEmpty 
              ? const Center(
                  child: Text('Aucune sourate trouvée', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                )
              : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                itemCount: filteredSurahs.length,
                itemBuilder: (context, index) {
                  final surah = filteredSurahs[index]; // ✨ Ab filtered data use hoga
                  
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    opacity: 0.55,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          surah.id.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryPink, fontSize: 14),
                        ),
                      ),
                      
                      title: Text(
                        surah.nameFrench,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                      subtitle: Text(
                        '${surah.revelationType} • ${surah.ayahCount} Versets',
                        style: TextStyle(fontSize: 12, color: AppTheme.textDark.withOpacity(0.5), fontWeight: FontWeight.w600),
                      ),
                      
                      trailing: Text(
                        surah.nameArabic,
                        style: const TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.w700, 
                          color: AppTheme.primaryPink, 
                          fontFamily: 'serif' 
                        ),
                      ),
                      
                      onTap: () {
                        ref.read(lastReadProvider.notifier).updateLastRead(
                          surahId: surah.id,
                          arabic: surah.nameArabic,
                          french: surah.nameFrench,
                          ayah: 1, 
                        );
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SurahReaderScreen(surahInfo: surah),
                          ),
                        );
                      },
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