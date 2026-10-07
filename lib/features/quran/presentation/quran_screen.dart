import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import '../data/surah_data.dart';
import 'quran_provider.dart';
import 'surah_reader_screen.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class QuranScreen extends ConsumerWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRead = ref.watch(lastReadProvider);

    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    final filteredSurahs = QuranData.surahs.where((surah) {
      return surah.nameFrench.toLowerCase().contains(searchQuery) ||
          surah.nameArabic.contains(searchQuery) ||
          surah.id.toString() == searchQuery;
    }).toList();

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Holy Quran', style: AppTextStyles.displayMedium),
              const SizedBox(height: 2),
              Text(
                'Peace & Serenity',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(CupertinoIcons.cloud_download, color: AppColors.gold, size: 24),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Offline mode active 📴',
                      style: TextStyle(color: AppColors.textPrimary)),
                  backgroundColor: AppColors.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: Column(
          children: [
            // 1. Last Read — hero card, more solid + gold glow icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: GestureDetector(
                onTap: () {
                  if (lastRead != null) {
                    final surahInfo =
                        QuranData.surahs.firstWhere((s) => s.id == lastRead.surahId);
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
                  opacity: 0.6,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.35),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(CupertinoIcons.book,
                            color: AppColors.background, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LAST READ',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.goldLight,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lastRead != null ? lastRead.surahNameFrench : 'Start Reading',
                              style: AppTextStyles.bodyLarge.copyWith(fontSize: 18),
                            ),
                            if (lastRead != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Verse ${lastRead.ayahNumber}',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (lastRead != null)
                        Icon(CupertinoIcons.chevron_right,
                            color: AppColors.gold.withOpacity(0.6), size: 18)
                    ],
                  ),
                ),
              ),
            ),

            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
              child: GlassCard(
                opacity: 0.3,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                  style: AppTextStyles.bodyLarge.copyWith(fontSize: 15),
                  cursorColor: AppColors.gold,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search a Surah...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
                    icon: Icon(CupertinoIcons.search, color: AppColors.gold),
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
                  Text('Surah Index', style: AppTextStyles.bodyLarge.copyWith(fontSize: 18)),
                  Text('${filteredSurahs.length} Surahs',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.gold, fontWeight: FontWeight.w700)),
                ],
              ),
            ),

            // 4. Surah List
            Expanded(
              child: filteredSurahs.isEmpty
                  ? Center(
                      child: Text('No Surah found',
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                      itemCount: filteredSurahs.length,
                      itemBuilder: (context, index) {
                        final surah = filteredSurahs[index];

                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          opacity: 0.3,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                            // Numbered badge — gold gradient ring instead of flat fill,
                            // this alone reads much more "premium" than a solid circle.
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.gold.withOpacity(0.25),
                                    AppColors.gold.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: AppColors.gold.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                surah.id.toString(),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.goldLight,
                                    fontSize: 14),
                              ),
                            ),

                            title: Text(
                              surah.nameFrench,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${surah.revelationType} • ${surah.ayahCount} Verses',
                                style: AppTextStyles.caption.copyWith(fontSize: 12),
                              ),
                            ),

                            // Arabic name — given more breathing room + the display
                            // serif so it feels like a typographic feature, not a label.
                            trailing: Text(
                              surah.nameArabic,
                              style: AppTextStyles.displayMedium.copyWith(
                                fontSize: 22,
                                color: AppColors.goldLight,
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