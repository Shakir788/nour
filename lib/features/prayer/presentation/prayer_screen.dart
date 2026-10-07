import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/adhan_scheduler.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import 'prayer_provider.dart';

final dailyAyahVisibilityProvider = StateProvider<bool>((ref) => true);

class PrayerScreen extends ConsumerWidget {
  const PrayerScreen({super.key});

  // Asli error ko samajhne layak message me badalta hai
  String _friendlyError(Object err) {
    final e = err.toString();
    if (e.contains('disabled')) {
      return 'Phone ka Location (GPS) band hai.\nUse ON karke Retry dabao.';
    }
    if (e.contains('permanently denied')) {
      return 'Location permission band hai.\nSettings me jaakar Allow karo.';
    }
    if (e.contains('permission denied')) {
      return 'Location permission nahi mili.\nRetry dabake Allow karo.';
    }
    if (e.contains('no GPS fix')) {
      return 'GPS fix nahi mila.\nKhuli jagah / khidki ke paas Retry karo.';
    }
    if (e.contains('SocketException') ||
        e.contains('ClientException') ||
        e.contains('Failed host lookup') ||
        e.contains('Cleartext')) {
      return 'Internet ya server se connect nahi ho paya.';
    }
    if (e.contains('TimeoutException')) {
      return 'Server ne time par jawab nahi diya.\nRetry karo.';
    }
    return 'Prayer times load nahi ho paye.';
  }

  void _retry(WidgetRef ref, DateTime activeDate) {
    ref.invalidate(userLocationProvider);
    ref.invalidate(cityNameProvider);
    ref.invalidate(livePrayerTimesProvider(activeDate));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDate = ref.watch(selectedPrayerDateProvider);
    final prayersNotifier = ref.read(prayersProvider.notifier);
    ref.watch(prayersProvider);

    final currentDayData = prayersNotifier.getPrayerForDate(activeDate);
    final completionPercent = currentDayData.completionPercentage;

    final locationAsync = ref.watch(cityNameProvider);
    final liveTimesAsync = ref.watch(livePrayerTimesProvider(activeDate));
    final dailyAyahAsync = ref.watch(dailyAyahProvider);
    final isAyatVisible = ref.watch(dailyAyahVisibilityProvider);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Divine Connection', style: AppTextStyles.displayMedium),
              const SizedBox(height: 2),
              locationAsync.when(
                loading: () => Text(
                  '📍 Detecting city...',
                  style: TextStyle(fontSize: 12, color: AppColors.goldLight),
                ),
                error: (_, __) => Text(
                  '📍 Local Timings',
                  style: TextStyle(fontSize: 12, color: AppColors.goldLight),
                ),
                data: (city) => Text(
                  '📍 $city',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                opacity: 0.6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            completionPercent == 1.0
                                ? 'All Prayers Done! ✨'
                                : 'Daily Connection',
                            style: AppTextStyles.bodyLarge.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Keep your heart calm and steady with your daily spiritual discipline.',
                            style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
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
                        '${(completionPercent * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.gold,
                        ),
                      ),
                      progressColor: AppColors.gold,
                      backgroundColor: AppColors.textMuted.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Horizontal Calendar
            _buildHorizontalCalendar(context, ref, activeDate),

            // 3. Prayer Times List
            Expanded(
              child: liveTimesAsync.when(
                loading: () => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.gold),
                      const SizedBox(height: 12),
                      Text(
                        'Fetching your local prayer times...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                error: (err, stack) => Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.location_slash,
                            color: Colors.redAccent, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          _friendlyError(err),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        // Asli error (debug ke liye) — chhota text
                        SelectableText(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () => _retry(ref, activeDate),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                              ),
                              child: const Text('Retry'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                await Geolocator.openLocationSettings();
                              },
                              child: const Text('GPS Settings'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                await Geolocator.openAppSettings();
                              },
                              child: const Text('App Permission'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                data: (liveTimes) {
                  final String formattedActiveDate =
                      DateFormat('yyyy-MM-dd').format(activeDate);

                  // Adhan schedule karo — sirf aaj ke liye
                  if (DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
                      formattedActiveDate) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      AdhanScheduler.scheduleAdhansForNext15Days();
                    });
                  }

                  final List<Map<String, dynamic>> prayerItems = [
                    {
                      'name': 'Fajr',
                      'time': liveTimes['fajr'],
                      'icon': CupertinoIcons.sunrise,
                      'key': 'fajr',
                      'status': currentDayData.fajr,
                    },
                    {
                      'name': 'Dhuhr',
                      'time': liveTimes['dhuhr'],
                      'icon': CupertinoIcons.sun_max,
                      'key': 'dhuhr',
                      'status': currentDayData.dhuhr,
                    },
                    {
                      'name': 'Asr',
                      'time': liveTimes['asr'],
                      'icon': CupertinoIcons.cloud_sun,
                      'key': 'asr',
                      'status': currentDayData.asr,
                    },
                    {
                      'name': 'Maghrib',
                      'time': liveTimes['maghrib'],
                      'icon': CupertinoIcons.sunset,
                      'key': 'maghrib',
                      'status': currentDayData.maghrib,
                    },
                    {
                      'name': 'Isha',
                      'time': liveTimes['isha'],
                      'icon': CupertinoIcons.moon_stars,
                      'key': 'isha',
                      'status': currentDayData.isha,
                    },
                  ];

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    itemCount: prayerItems.length,
                    itemBuilder: (context, index) {
                      final item = prayerItems[index];
                      final bool isDone = item['status'] as bool;

                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        opacity: isDone ? 0.55 : 0.3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? AppColors.gold.withValues(alpha: 0.2)
                                  : AppColors.textMuted.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDone
                                    ? AppColors.gold.withValues(alpha: 0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: isDone ? AppColors.gold : AppColors.textMuted,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            item['name'] as String,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDone
                                  ? AppColors.gold
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            item['time'] as String,
                            style: AppTextStyles.bodyMedium,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(CupertinoIcons.bell,
                                    color: AppColors.gold.withValues(alpha: 0.6),
                                    size: 22),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Adhan synced for ${item['name']}! 🔔'),
                                      backgroundColor: AppColors.surfaceElevated,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              Transform.scale(
                                scale: 1.1,
                                child: Checkbox(
                                  value: isDone,
                                  activeColor: AppColors.gold,
                                  checkColor: AppColors.background,
                                  side: BorderSide(
                                      color: AppColors.textMuted
                                          .withValues(alpha: 0.4),
                                      width: 2),
                                  shape: const CircleBorder(),
                                  onChanged: (_) => ref
                                      .read(prayersProvider.notifier)
                                      .togglePrayer(
                                          activeDate, item['key'] as String),
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

            // 4. Daily Ayah Card
            if (isAyatVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 5, 24, 20),
                child: Stack(
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      opacity: 0.55,
                      child: dailyAyahAsync.when(
                        loading: () => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child:
                                CircularProgressIndicator(color: AppColors.gold),
                          ),
                        ),
                        error: (err, stack) => Text(
                          'Could not fetch daily Ayah.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        data: (dailyAyah) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: InkWell(
                                onTap: () => ref.invalidate(dailyAyahProvider),
                                child: Icon(CupertinoIcons.refresh,
                                    size: 20,
                                    color: AppColors.gold.withValues(alpha: 0.6)),
                              ),
                            ),
                            Text(
                              dailyAyah['arabic']!,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                                fontFamily: AppTextStyles.displayMedium.fontFamily,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              dailyAyah['translation']!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dailyAyah['reference']!,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      left: 5,
                      child: IconButton(
                        icon: Icon(CupertinoIcons.clear,
                            size: 22, color: AppColors.textMuted),
                        onPressed: () {
                          ref.read(dailyAyahVisibilityProvider.notifier).state =
                              false;
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

  Widget _buildHorizontalCalendar(
      BuildContext context, WidgetRef ref, DateTime activeDate) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 14,
        itemBuilder: (context, index) {
          final day = DateTime.now()
              .subtract(const Duration(days: 7))
              .add(Duration(days: index));
          final bool isSelected = DateFormat('yyyy-MM-dd').format(day) ==
              DateFormat('yyyy-MM-dd').format(activeDate);

          return GestureDetector(
            onTap: () =>
                ref.read(selectedPrayerDateProvider.notifier).state = day,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold
                    : AppColors.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold
                      : AppColors.textMuted.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? AppColors.background : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}