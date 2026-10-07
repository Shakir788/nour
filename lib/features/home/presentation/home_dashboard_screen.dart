import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adhan/adhan.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/neki_provider.dart';
import '../../../shared/widgets/premium_drawer.dart';
import '../../../core/providers/streak_provider.dart';
import '../../../core/services/smart_location_service.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  // Timer & Prayer Variables
  Timer? _countdownTimer;
  Prayer? _nextPrayer;
  Duration _timeUntilNextPrayer = Duration.zero;
  bool _isLoadingPrayer = true;

  // Location + calculation params (timer inhi ko use karta hai)
  Coordinates? _coords;
  late final CalculationParameters _params;
  String _locationLabel = '';

  // Dua of the Day Variables
  Map<String, dynamic>? _duaOfTheDay;
  bool _isLoadingDua = true;
  bool _hasClaimedDailyDuaNeki = false;

  @override
  void initState() {
    super.initState();
    _params = CalculationMethod.karachi.getParameters();
    _params.madhab = Madhab.hanafi;
    _initDashboardData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDashboardData() async {
    await Future.wait([
      _setupPrayerCountdown(),
      _loadDuaOfTheDay(),
    ]);
  }

  // ✨ PRAYER COUNTDOWN ENGINE
  Future<void> _setupPrayerCountdown() async {
    // 1. Pehle saved/default location se turant countdown dikha do (user ko wait nahi)
    final offline = await SmartLocationService.getOfflineLocation();
    if (!mounted) return;
    _coords = Coordinates(offline['latitude']!, offline['longitude']!);
    _locationLabel = (await SmartLocationService.getSavedLocation()) != null
        ? 'Saved location'
        : 'Default location';
    _updatePrayerTimes();

    // 2. Timer: har second update
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updatePrayerTimes();
    });

    // 3. Background me live GPS lo, mil jaye to coordinates update kar do
    _refreshLiveLocation();
  }

  Future<void> _refreshLiveLocation() async {
    final loc = await SmartLocationService.getBestLocation();
    if (!mounted) return;

    final source = SmartLocationService.lastSource;
    setState(() {
      _coords = Coordinates(loc['latitude']!, loc['longitude']!);
      switch (source) {
        case LocationSource.live:
          _locationLabel = 'Live location';
          break;
        case LocationSource.saved:
          _locationLabel = 'Saved location';
          break;
        case LocationSource.defaultFallback:
          _locationLabel = 'Default location (GPS unavailable)';
          break;
      }
    });
    _updatePrayerTimes();
  }

  void _updatePrayerTimes() {
    final coords = _coords;
    if (coords == null) return;

    final now = DateTime.now();
    final prayerTimes = PrayerTimes.today(coords, _params);

    Prayer next = prayerTimes.nextPrayer();
    DateTime? nextPrayerTime = prayerTimes.timeForPrayer(next);

    // Aaj ki saari namaz ho gayi to kal ki Fajr
    if (next == Prayer.none || nextPrayerTime == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowPrayerTimes = PrayerTimes(
        coords,
        DateComponents(tomorrow.year, tomorrow.month, tomorrow.day),
        _params,
      );
      next = Prayer.fajr;
      nextPrayerTime = tomorrowPrayerTimes.fajr;
    }

    if (mounted) {
      setState(() {
        _nextPrayer = next;
        _timeUntilNextPrayer = nextPrayerTime!.difference(now);
        _isLoadingPrayer = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String _getPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return "Fajr";
      case Prayer.sunrise:
        return "Sunrise";
      case Prayer.dhuhr:
        return "Dhuhr";
      case Prayer.asr:
        return "Asr";
      case Prayer.maghrib:
        return "Maghrib";
      case Prayer.isha:
        return "Isha";
      default:
        return "Next Prayer";
    }
  }

  // ✨ SMART DUA OF THE DAY ENGINE
  Future<void> _loadDuaOfTheDay() async {
    try {
      final String response = await rootBundle.loadString('assets/data/all_duas.json');
      final data = await json.decode(response);
      List<dynamic> allDuas = data['duas'];

      if (allDuas.isNotEmpty) {
        final random = Random();
        final selectedDua = allDuas[random.nextInt(allDuas.length)];
        if (mounted) {
          setState(() {
            _duaOfTheDay = selectedDua;
            _isLoadingDua = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoadingDua = false);
      }
    } catch (e) {
      debugPrint("Error loading Dua: $e");
      if (mounted) setState(() => _isLoadingDua = false);
    }
  }

  void _claimDailyDuaNeki() {
    if (!_hasClaimedDailyDuaNeki) {
      HapticFeedback.heavyImpact();
      ref.read(nekiProvider.notifier).addNekis(20);
      setState(() {
        _hasClaimedDailyDuaNeki = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Text("🌟", style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text("Awesome! +20 Neki Earned.",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.background)),
            ],
          ),
          backgroundColor: AppColors.gold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final totalNekis = ref.watch(nekiProvider);
    final streak = ref.watch(streakProvider);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const PremiumDrawer(),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. GAMIFICATION HUD (Top Bar)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(CupertinoIcons.bars, color: AppColors.gold, size: 28),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    GlassCard(
                      opacity: 0.4,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("🔥", style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text(
                            "$streak",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 16, color: AppColors.divider),
                          const SizedBox(width: 12),
                          const Text("✨", style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text(
                            "$totalNekis",
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. WELCOME HEADER
                Text(
                  "Assalamu Alaikum,",
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  userName.isNotEmpty ? userName : "Beautiful Soul",
                  style: AppTextStyles.displayLarge.copyWith(fontSize: 32, color: AppColors.gold),
                ),
                const SizedBox(height: 32),

                // 3. HERO SECTION (Prayer Countdown)
                _isLoadingPrayer
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : GlassCard(
                        opacity: 0.2,
                        padding: const EdgeInsets.all(24),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -30,
                              top: -30,
                              child: Icon(
                                CupertinoIcons.clock_fill,
                                size: 150,
                                color: AppColors.gold.withValues(alpha: 0.05),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(CupertinoIcons.moon_stars_fill,
                                          color: AppColors.gold, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Next Prayer",
                                      style: AppTextStyles.bodyLarge
                                          .copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _getPrayerName(_nextPrayer ?? Prayer.none),
                                      style: AppTextStyles.displayLarge.copyWith(fontSize: 42, color: Colors.white),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        "- ${_formatDuration(_timeUntilNextPrayer)}",
                                        style: AppTextStyles.displayMedium
                                            .copyWith(fontSize: 24, color: AppColors.goldLight),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_locationLabel.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    "📍 $_locationLabel",
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.5),
                                      foregroundColor: AppColors.gold,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      // Navigate to Qibla or detailed prayer times
                                    },
                                    child: const Text("View Full Schedule",
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                const SizedBox(height: 32),

                // 4. SMART DUA OF THE DAY
                Row(
                  children: [
                    const Text("📖", style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(
                      "Daily Inspiration",
                      style: AppTextStyles.displayMedium.copyWith(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _isLoadingDua
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : _duaOfTheDay == null
                        ? const SizedBox.shrink()
                        : GlassCard(
                            opacity: 0.6,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(
                                  _duaOfTheDay!['arabic'] ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 26,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _duaOfTheDay!['meaning'] ?? '',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: AppColors.textMuted, fontSize: 14),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _hasClaimedDailyDuaNeki
                                          ? AppColors.surfaceElevated.withValues(alpha: 0.3)
                                          : AppColors.gold,
                                      foregroundColor:
                                          _hasClaimedDailyDuaNeki ? AppColors.gold : AppColors.background,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      elevation: _hasClaimedDailyDuaNeki ? 0 : 8,
                                      shadowColor: AppColors.gold.withValues(alpha: 0.5),
                                    ),
                                    onPressed: _hasClaimedDailyDuaNeki ? null : _claimDailyDuaNeki,
                                    icon: Icon(_hasClaimedDailyDuaNeki
                                        ? CupertinoIcons.check_mark_circled_solid
                                        : CupertinoIcons.heart_solid),
                                    label: Text(
                                      _hasClaimedDailyDuaNeki ? "Earned +20 Neki" : "Read & Earn +20 Neki",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}