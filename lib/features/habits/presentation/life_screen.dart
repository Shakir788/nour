import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../chat/nour_screen.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import '../presentation/habit_provider.dart';
import '../../prayer/presentation/prayer_provider.dart';
import '../../chat/nour_screen.dart'; // Naya import for Nour AI chat
import 'wellness_provider.dart';
import 'journal_screen.dart';

class LifeScreen extends ConsumerStatefulWidget {
  const LifeScreen({super.key});

  @override
  ConsumerState<LifeScreen> createState() => _LifeScreenState();
}

class _LifeScreenState extends ConsumerState<LifeScreen> {
  static const int focusDuration = 1800;
  int _timeLeft = focusDuration;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _stopTimer();
        ref.read(habitNotifierProvider.notifier).addProjectSession();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _timeLeft = focusDuration;
    });
  }

  String get timerString {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int _prayerDaysThisWeek(WidgetRef ref) {
    final notifier = ref.read(prayersProvider.notifier);
    ref.watch(prayersProvider);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int fullDays = 0;
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (day.isAfter(now)) break;
      if (notifier.getPrayerForDate(day).completionPercentage == 1.0) fullDays++;
    }
    return fullDays;
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitNotifierProvider);
    final wellness = ref.watch(wellnessProvider);
    final wellnessNotifier = ref.read(wellnessProvider.notifier);
    final prayerDays = _prayerDaysThisWeek(ref);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // NAYA: Islamic background image low opacity ke sath
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/images/islamic_bg.png',
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.5),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Wellness', style: AppTextStyles.displayMedium.copyWith(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text('Take care of yourself', style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: habits == null
                        ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            children: [
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                opacity: 0.4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(CupertinoIcons.sparkles, color: AppColors.gold, size: 22),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "Don't forget to stay hydrated today.",
                                            style: AppTextStyles.bodyLarge.copyWith(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      child: Divider(color: AppColors.divider, thickness: 1),
                                    ),
                                    Text(
                                      '"Allah does not burden a soul beyond that it can bear."',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.goldLight,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Surah Al-Baqarah (2:286)', style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context, MaterialPageRoute(builder: (context) => const JournalScreen())),
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
                                        ),
                                        child: Icon(CupertinoIcons.book_fill,
                                            color: AppColors.background, size: 26),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('PERSONAL SPACE',
                                                style: AppTextStyles.caption
                                                    .copyWith(color: AppColors.goldLight, letterSpacing: 1)),
                                            const SizedBox(height: 4),
                                            Text('My Private Journal', style: AppTextStyles.bodyLarge),
                                          ],
                                        ),
                                      ),
                                      Icon(CupertinoIcons.chevron_right,
                                          color: AppColors.gold.withOpacity(0.6), size: 18),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              Text('This Week', style: AppTextStyles.bodyLarge.copyWith(fontSize: 18)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _StatTile(label: 'Prayers', value: '$prayerDays/7'),
                                  const SizedBox(width: 10),
                                  _StatTile(label: 'Fasts', value: '${wellnessNotifier.fastsThisWeek}/7'),
                                  const SizedBox(width: 10),
                                  _StatTile(
                                    label: 'Sadaqah',
                                    value: wellnessNotifier.sadaqahThisMonth > 0
                                        ? wellnessNotifier.sadaqahThisMonth.toStringAsFixed(0)
                                        : '0',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              Text('Dhikr Counter', style: AppTextStyles.bodyLarge.copyWith(fontSize: 18)),
                              const SizedBox(height: 12),
                              GlassCard(
                                padding: const EdgeInsets.all(24),
                                opacity: 0.4,
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: wellnessNotifier.incrementDhikr,
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.gold.withOpacity(0.2),
                                              blurRadius: 24,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${wellness.dhikrCount}',
                                          style: AppTextStyles.displayLarge.copyWith(
                                              fontSize: 40, color: AppColors.gold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('Tap to count', style: AppTextStyles.caption),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        TextButton(
                                          onPressed: wellnessNotifier.cycleDhikrTarget,
                                          child: Text('Target: ${wellness.dhikrTarget}',
                                              style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 12),
                                        TextButton(
                                          onPressed: wellnessNotifier.resetDhikr,
                                          child: Text('Reset',
                                              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Sadaqah Tracker', style: AppTextStyles.bodyLarge.copyWith(fontSize: 18)),
                                  TextButton.icon(
                                    onPressed: () => _showAddSadaqahSheet(context, wellnessNotifier),
                                    icon: Icon(CupertinoIcons.add, size: 18, color: AppColors.gold),
                                    label: Text('Add', style: TextStyle(color: AppColors.gold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                opacity: 0.4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('This month', style: AppTextStyles.caption),
                                    const SizedBox(height: 4),
                                    Text(
                                      wellnessNotifier.sadaqahThisMonth.toStringAsFixed(0),
                                      style: AppTextStyles.displayMedium.copyWith(color: AppColors.gold),
                                    ),
                                    if (wellness.sadaqahEntries.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      Divider(color: AppColors.divider),
                                      const SizedBox(height: 8),
                                      ...wellness.sadaqahEntries.reversed.take(3).map(
                                            (e) => Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    e.note.isEmpty ? 'Sadaqah' : e.note,
                                                    style: AppTextStyles.bodyMedium,
                                                  ),
                                                  Text(e.amount.toStringAsFixed(0),
                                                      style: TextStyle(
                                                          color: AppColors.textPrimary,
                                                          fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            ),
                                          ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              Text('Fasting Tracker', style: AppTextStyles.bodyLarge.copyWith(fontSize: 18)),
                              const SizedBox(height: 4),
                              Text('Mon & Thu are marked as Sunnah fasting days',
                                  style: AppTextStyles.caption),
                              const SizedBox(height: 12),
                              GlassCard(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                opacity: 0.4,
                                child: _FastingWeekRow(wellnessNotifier: wellnessNotifier),
                              ),
                              const SizedBox(height: 28),

                              Text('Daily Habits', style: AppTextStyles.bodyLarge.copyWith(fontSize: 18)),
                              const SizedBox(height: 12),
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                opacity: 0.4,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                              color: AppColors.gold.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(16)),
                                          child: Icon(CupertinoIcons.drop_fill, color: AppColors.gold, size: 28),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Hydration', style: AppTextStyles.bodyLarge),
                                              const SizedBox(height: 4),
                                              Text('${habits.waterIntakeMl} / 2000 ml',
                                                  style: AppTextStyles.bodyMedium),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => ref.read(habitNotifierProvider.notifier).addWater(250),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.gold,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Icon(CupertinoIcons.add, color: AppColors.background, size: 24),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: (habits.waterIntakeMl / 2000).clamp(0.0, 1.0),
                                        backgroundColor: AppColors.textMuted.withOpacity(0.15),
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                opacity: 0.4,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: AppColors.gold.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(16)),
                                      child: Icon(Icons.fitness_center_rounded, color: AppColors.gold, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Workout Session', style: AppTextStyles.bodyLarge),
                                          const SizedBox(height: 4),
                                          Text(habits.gymAttended ? 'Goal reached' : 'To do today',
                                              style: AppTextStyles.bodyMedium),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          ref.read(habitNotifierProvider.notifier).toggleGym(!habits.gymAttended),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: habits.gymAttended ? AppColors.gold : Colors.transparent,
                                          border: Border.all(
                                              color: habits.gymAttended
                                                  ? AppColors.gold
                                                  : AppColors.textMuted.withOpacity(0.4),
                                              width: 2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: habits.gymAttended
                                            ? Icon(Icons.check, color: AppColors.background, size: 20)
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              GlassCard(
                                padding: const EdgeInsets.all(28),
                                opacity: 0.4,
                                child: Column(
                                  children: [
                                    Text('Focus Mode', style: AppTextStyles.bodyLarge.copyWith(fontSize: 18)),
                                    const SizedBox(height: 8),
                                    Text('${habits.projectSessions} sessions completed',
                                        style: AppTextStyles.bodyMedium),
                                    const SizedBox(height: 28),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                                      decoration: BoxDecoration(
                                        color: _isRunning
                                            ? AppColors.gold.withOpacity(0.1)
                                            : AppColors.surfaceElevated.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                            color: _isRunning ? AppColors.gold.withOpacity(0.5) : Colors.transparent),
                                      ),
                                      child: Text(
                                        timerString,
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w800,
                                          color: _isRunning ? AppColors.gold : AppColors.textPrimary,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isRunning ? _stopTimer : _startTimer,
                                        child: Text(_isRunning ? 'Pause' : 'Start Focus'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 80), // Thoda space for FAB
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // NAYA: Floating Action Button for Nour AI
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NourScreen()),
            );
          },
          backgroundColor: Colors.indigoAccent,
          elevation: 6,
          child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showAddSadaqahSheet(BuildContext context, WellnessNotifier notifier) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Sadaqah', style: AppTextStyles.displayMedium.copyWith(fontSize: 20)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount > 0) {
                      notifier.addSadaqah(amount, noteController.text.trim());
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        opacity: 0.4,
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.bodyLarge.copyWith(fontSize: 18, color: AppColors.gold)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _FastingWeekRow extends StatelessWidget {
  final WellnessNotifier wellnessNotifier;
  const _FastingWeekRow({required this.wellnessNotifier});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final isSunnahDay = day.weekday == DateTime.monday || day.weekday == DateTime.thursday;
        final isFasted = wellnessNotifier.isFastedOn(day);
        final isFuture = day.isAfter(now);

        return GestureDetector(
          onTap: isFuture ? null : () => wellnessNotifier.toggleFast(day),
          child: Opacity(
            opacity: isFuture ? 0.35 : 1,
            child: Column(
              children: [
                Text(DateFormat('E').format(day).substring(0, 1),
                    style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFasted ? AppColors.gold : Colors.transparent,
                    border: Border.all(
                      color: isFasted
                          ? AppColors.gold
                          : (isSunnahDay
                              ? AppColors.gold.withOpacity(0.5)
                              : AppColors.textMuted.withOpacity(0.3)),
                      width: isSunnahDay && !isFasted ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isFasted
                      ? Icon(Icons.check, size: 18, color: AppColors.background)
                      : null,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}