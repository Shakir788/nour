import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/greeting_helper.dart';
import '../../../core/utils/cat_behavior_helper.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import 'schedule_provider.dart';
import 'lulu_cat_widget.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> with TickerProviderStateMixin {
  // Teeno parts ke alag animation controllers
  late final AnimationController _headAnimController;
  late final AnimationController _tailAnimController;
  late final AnimationController _bodyAnimController;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _headAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _tailAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _bodyAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _headAnimController.dispose();
    _tailAnimController.dispose();
    _bodyAnimController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ✨ Phase 3 Real Interaction Logic: Pet specific parts & play sounds
  Future<void> _handleCatPet(String behavior, String meowType) async {
    final random = Random();

    if (behavior == 'head') {
      _headAnimController.forward().then((_) => _headAnimController.reverse());
    } else if (behavior == 'tail') {
      _tailAnimController.forward().then((_) => _tailAnimController.reverse());
    } else if (behavior == 'body') {
      _bodyAnimController.forward().then((_) => _bodyAnimController.reverse());
    }

    try {
      final sounds = CatBehaviorHelper.behaviorSounds[meowType] ?? CatBehaviorHelper.behaviorSounds['happy']!;
      await _audioPlayer.play(UrlSource(sounds[random.nextInt(sounds.length)]));
    } catch (e) {
      debugPrint("Audio Error: $e");
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          CatBehaviorHelper.behaviorMessages[behavior]![random.nextInt(CatBehaviorHelper.behaviorMessages[behavior]!.length)],
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 15),
        ),
        backgroundColor: behavior == 'tail' ? Colors.redAccent.withOpacity(0.4) : const Color(0xFFFFD1DC),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    String timeStr = '';
    String dateStr = DateFormat('yyyy-MM-dd').format(ref.read(selectedDateProvider));
    TimeOfDay? pickedTime;
    DateTime? pickedDate = ref.read(selectedDateProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (context, setSheetState) => GlassCard(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppTheme.primaryPink.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                ),
                const Text('New Routine ✨', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerButton(
                        icon: Icons.calendar_today_rounded,
                        label: pickedDate == null ? 'Date' : DateFormat('dd MMM').format(pickedDate!),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: pickedDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: AppTheme.primaryPink, onPrimary: Colors.white, onSurface: AppTheme.textDark),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) setSheetState(() { pickedDate = date; dateStr = DateFormat('yyyy-MM-dd').format(date); });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPickerButton(
                        icon: Icons.access_time_rounded,
                        label: pickedTime == null ? 'Time' : timeStr,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: AppTheme.primaryPink, onPrimary: Colors.white, onSurface: AppTheme.textDark),
                              ),
                              child: child!,
                            ),
                          );
                          if (time != null) setSheetState(() { pickedTime = time; timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'; });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Plan for the day... 🌸',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.all(15),
                      elevation: 4,
                      shadowColor: AppTheme.primaryPink.withOpacity(0.5),
                    ),
                    onPressed: () {
                      if (timeStr.isNotEmpty && titleController.text.isNotEmpty) {
                        ref.read(scheduleNotifierProvider.notifier).addTask(timeStr, titleController.text.trim(), dateStr);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Save to Routine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryPink.withOpacity(0.2))),
        child: Row(children: [Icon(icon, size: 18, color: AppTheme.primaryPink), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))]),
      ),
    );
  }

  // ✨ Lulu cat widget — fully code-drawn, no image assets needed
  Widget _buildLuluCat() {
    // ⚠️ FIXED: Changed from LuluCatWidget to LuluPetWidget
    return AnimatedBuilder(
      animation: Listenable.merge([_headAnimController, _bodyAnimController, _tailAnimController]),
      builder: (context, child) {
        return LuluPetWidget(
          width: 300,
          height: 120,
          onTap: () => _handleCatPet('head', 'happy'), 
          onFedHappy: () => _handleCatPet('body', 'happy'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(scheduleNotifierProvider);
    final activeDate = ref.watch(selectedDateProvider);
    bool isToday = DateFormat('yyyy-MM-dd').format(activeDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('My Routine 🌸',
              style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          centerTitle: false,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryPink,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onPressed: () => _showAddTaskSheet(context),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday ? GreetingHelper.getGreeting() : 'Upcoming Plans',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryPink, letterSpacing: -1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, d MMMM').format(activeDate),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark.withOpacity(0.55)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Tap Lulu pour un câlin 🐾",
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textLight.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),

                    // ✨ Lulu the cat 
                    _buildLuluCat(),
                  ],
                ),
              ),

              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(color: AppTheme.primaryPink.withOpacity(0.08), shape: BoxShape.circle),
                              child: Icon(Icons.spa_outlined, size: 60, color: AppTheme.primaryPink.withOpacity(0.4)),
                            ),
                            const SizedBox(height: 16),
                            const Text('Your garden is empty.',
                                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Tap Lulu or add a task to begin 🌸',
                                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textLight.withOpacity(0.8), fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Dismissible(
                            key: Key(task.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                            ),
                            onDismissed: (dir) => ref.read(scheduleNotifierProvider.notifier).deleteTask(task.id!),
                            child: GlassCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              opacity: 0.7,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: AppTheme.primaryPink.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Text(task.time, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryPink, fontSize: 14)),
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted ? AppTheme.textLight : AppTheme.textDark,
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: task.isCompleted,
                                  activeColor: AppTheme.primaryPink,
                                  shape: const CircleBorder(),
                                  onChanged: (val) {
                                    if (task.id != null) {
                                      ref.read(scheduleNotifierProvider.notifier).toggleTaskStatus(task.id!, task.isCompleted);
                                      if (!task.isCompleted) _handleCatPet('head', 'happy');
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}