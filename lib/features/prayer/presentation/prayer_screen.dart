import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import '../../../core/services/adhan_scheduler.dart'; 
import 'prayer_provider.dart';

final dailyAyahVisibilityProvider = StateProvider<bool>((ref) => true);

class PrayerScreen extends ConsumerWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDate = ref.watch(selectedPrayerDateProvider);
    final prayersNotifier = ref.read(prayersProvider.notifier);
    ref.watch(prayersProvider); 
    
    final currentDayData = prayersNotifier.getPrayerForDate(activeDate);
    final completionPercent = currentDayData.completionPercentage;

    // ✨ Fetch Live APIs (Ab ye activeDate ke hisaab se fetch karega)
    final liveTimesAsync = ref.watch(livePrayerTimesProvider(activeDate));
    final dailyAyahAsync = ref.watch(dailyAyahProvider); 
    
    // Ayat card ki visibility state
    final isAyatVisible = ref.watch(dailyAyahVisibilityProvider);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spiritual Journey 🕌', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 22)),
              Text('📍 Morocco Timings', style: TextStyle(fontSize: 12, color: AppTheme.primaryPink, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        body: Column(
          children: [
            // 1. Progress Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                opacity: 0.7,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            completionPercent == 1.0 ? 'All Prayers Done! ✨' : 'Daily Connection',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Keep your heart calm and steady with your daily spiritual discipline.',
                            style: TextStyle(fontSize: 13, color: AppTheme.textDark.withOpacity(0.6), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    CircularPercentIndicator(
                      radius: 45.0,
                      lineWidth: 8.0,
                      percent: completionPercent,
                      animation: true,
                      animateFromLastPercent: true,
                      circularStrokeCap: CircularStrokeCap.round,
                      center: Text(
                        "${(completionPercent * 100).toInt()}%",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryPink),
                      ),
                      progressColor: AppTheme.primaryPink,
                      backgroundColor: AppTheme.primaryPink.withOpacity(0.15),
                    )
                  ],
                ),
              ),
            ),

            // 2. Calendar
            _buildHorizontalCalendar(context, ref, activeDate),

            // 3. Live API Prayers List
            Expanded(
              child: liveTimesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryPink)),
                error: (err, stack) => Center(child: Text('Internet lag rha hai... 🌸\n$err', textAlign: TextAlign.center)),
                data: (liveTimes) {
                  
                  // ✨ FIX: Riverpod Error solve karne ke liye post frame callback lagaya
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AdhanScheduler.scheduleDailyAdhan(prayerName: 'Fajr', timeStr: liveTimes['fajr']!, notificationId: 101);
                    AdhanScheduler.scheduleDailyAdhan(prayerName: 'Dhuhr', timeStr: liveTimes['dhuhr']!, notificationId: 102);
                    AdhanScheduler.scheduleDailyAdhan(prayerName: 'Asr', timeStr: liveTimes['asr']!, notificationId: 103);
                    AdhanScheduler.scheduleDailyAdhan(prayerName: 'Maghrib', timeStr: liveTimes['maghrib']!, notificationId: 104);
                    AdhanScheduler.scheduleDailyAdhan(prayerName: 'Isha', timeStr: liveTimes['isha']!, notificationId: 105);
                  });

                  final List<Map<String, dynamic>> prayerItems = [
                    {'name': 'Fajr', 'time': liveTimes['fajr'], 'icon': Icons.wb_twighlight, 'key': 'fajr', 'status': currentDayData.fajr},
                    {'name': 'Dhuhr', 'time': liveTimes['dhuhr'], 'icon': Icons.wb_sunny_rounded, 'key': 'dhuhr', 'status': currentDayData.dhuhr},
                    {'name': 'Asr', 'time': liveTimes['asr'], 'icon': Icons.wb_cloudy_rounded, 'key': 'asr', 'status': currentDayData.asr},
                    {'name': 'Maghrib', 'time': liveTimes['maghrib'], 'icon': Icons.dark_mode_rounded, 'key': 'maghrib', 'status': currentDayData.maghrib},
                    {'name': 'Isha', 'time': liveTimes['isha'], 'icon': Icons.nightlight_round, 'key': 'isha', 'status': currentDayData.isha},
                  ];

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    itemCount: prayerItems.length,
                    itemBuilder: (context, index) {
                      final item = prayerItems[index];
                      final bool isDone = item['status'] as bool;

                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        opacity: isDone ? 0.8 : 0.55,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDone ? AppTheme.primaryPink.withOpacity(0.15) : Colors.white.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item['icon'] as IconData, color: isDone ? AppTheme.primaryPink : AppTheme.textLight, size: 24),
                          ),
                          title: Text(item['name'] as String, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: isDone ? AppTheme.primaryPink : AppTheme.textDark)),
                          subtitle: Text(item['time'] as String, style: TextStyle(fontSize: 13, color: AppTheme.textDark.withOpacity(0.6), fontWeight: FontWeight.w600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.notifications_active_outlined, color: AppTheme.primaryPink.withOpacity(0.6), size: 22),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Adhan alert synced for ${item['name']}! 🔔'),
                                    backgroundColor: AppTheme.primaryPink,
                                    duration: const Duration(seconds: 2),
                                  ));
                                },
                              ),
                              Transform.scale(
                                scale: 1.1,
                                child: Checkbox(
                                  value: isDone,
                                  activeColor: AppTheme.primaryPink,
                                  shape: const CircleBorder(),
                                  onChanged: (_) => ref.read(prayersProvider.notifier).togglePrayer(activeDate, item['key'] as String),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ✨ 4. Live Ayah Card (Ab hide bhi ho sakta hai!)
            if (isAyatVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 5, 24, 20),
                child: Stack(
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      opacity: 0.6,
                      child: dailyAyahAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: CircularProgressIndicator(color: AppTheme.primaryPink),
                          )
                        ),
                        error: (err, stack) => const Text('Could not fetch daily Ayah.', textAlign: TextAlign.center),
                        data: (dailyAyah) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: InkWell(
                                onTap: () => ref.invalidate(dailyAyahProvider), 
                                child: Icon(Icons.refresh_rounded, size: 20, color: AppTheme.primaryPink.withOpacity(0.6)),
                              ),
                            ),
                            Text(
                              dailyAyah['arabic']!,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl, // Added text direction for Arabic
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryPink, fontFamily: 'serif', height: 1.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              dailyAyah['translation']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dailyAyah['reference']!,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textDark.withOpacity(0.4), letterSpacing: 0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ✨ Cross (Close) Button
                    Positioned(
                      top: 5,
                      left: 5,
                      child: IconButton(
                        icon: Icon(Icons.close_rounded, size: 22, color: AppTheme.textDark.withOpacity(0.4)),
                        onPressed: () {
                          // Isko dabate hi card gayab ho jayega
                          ref.read(dailyAyahVisibilityProvider.notifier).state = false;
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCalendar(BuildContext context, WidgetRef ref, DateTime activeDate) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 14,
        itemBuilder: (context, index) {
          // Changed to show past 7 days and future 7 days
          final day = DateTime.now().subtract(const Duration(days: 7)).add(Duration(days: index));
          final bool isSelected = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(activeDate);

          return GestureDetector(
            onTap: () => ref.read(selectedPrayerDateProvider.notifier).state = day,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryPink : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppTheme.primaryPink : AppTheme.primaryPink.withOpacity(0.1), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E').format(day).toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.textLight)),
                  const SizedBox(height: 5),
                  Text(DateFormat('d').format(day), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : AppTheme.textDark)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}