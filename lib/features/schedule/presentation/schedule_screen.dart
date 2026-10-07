import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection; 

import '../../../shared/widgets/premium_drawer.dart'; // ✨ Drawer Import
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/user_provider.dart'; 
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';
import '../../chat/nour_screen.dart'; 
import 'schedule_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
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
            opacity: 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text('New Routine', style: AppTextStyles.displayMedium.copyWith(fontSize: 22)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerButton(
                        icon: CupertinoIcons.calendar,
                        label: pickedDate == null ? 'Date' : DateFormat('dd MMM').format(pickedDate!),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: pickedDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: AppColors.gold,
                                  onPrimary: AppColors.background,
                                  surface: AppColors.surfaceElevated,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) {
                            setSheetState(() {
                              pickedDate = date;
                              dateStr = DateFormat('yyyy-MM-dd').format(date);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPickerButton(
                        icon: CupertinoIcons.time,
                        label: pickedTime == null ? 'Time' : timeStr,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: AppColors.gold,
                                  onPrimary: AppColors.background,
                                  surface: AppColors.surfaceElevated,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (time != null) {
                            setSheetState(() {
                              pickedTime = time;
                              timeStr =
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Plan for the day...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface.withValues(alpha: 0.6),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.all(15),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (timeStr.isNotEmpty && titleController.text.isNotEmpty) {
                        ref
                            .read(scheduleNotifierProvider.notifier)
                            .addTask(timeStr, titleController.text.trim(), dateStr);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Save to Routine',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.gold),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(scheduleNotifierProvider);
    final activeDate = ref.watch(selectedDateProvider);
    final userName = ref.watch(userNameProvider);
    
    bool isToday = DateFormat('yyyy-MM-dd').format(activeDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        
        drawer: const PremiumDrawer(), // ✨ Drawer connected here
        
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Text('My Routine', style: AppTextStyles.displayMedium),
          
          // ✨ Hamburger Icon added to open Drawer
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(CupertinoIcons.bars, color: AppColors.gold, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
          
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. Nour AI Avatar Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NourScreen()),
                  );
                },
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/icon/app_icon.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 2. Add Routine Button
              FloatingActionButton(
                heroTag: 'add_task_fab',
                backgroundColor: AppColors.gold,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () => _showAddTaskSheet(context),
                child: Icon(CupertinoIcons.add, color: AppColors.background, size: 28),
              ),
            ],
          ),
        ),
        
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isToday)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 15 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'السلام عليكم',
                                  style: AppTextStyles.displayLarge.copyWith(
                                    fontSize: 42, 
                                    color: AppColors.gold,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userName.isNotEmpty ? 'Peace be upon you, $userName ✨' : 'Peace be upon you ✨',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontSize: 18,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            'Upcoming Plans',
                            style: AppTextStyles.displayLarge.copyWith(
                                fontSize: 32, color: AppColors.gold),
                          ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Icon(CupertinoIcons.calendar, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('EEEE, d MMMM').format(activeDate),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(CupertinoIcons.list_bullet,
                                      size: 60, color: AppColors.gold.withValues(alpha: 0.4)),
                                ),
                                const SizedBox(height: 16),
                                Text('Your routine is empty.',
                                    textAlign: TextAlign.center, style: AppTextStyles.bodyLarge),
                                const SizedBox(height: 6),
                                Text('Tap the + to add a new task',
                                    textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];

                              return Dismissible(
                                key: Key(task.id.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(CupertinoIcons.delete, color: Colors.white, size: 28),
                                ),
                                onDismissed: (dir) =>
                                    ref.read(scheduleNotifierProvider.notifier).deleteTask(task.id!),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: GlassCard(
                                    padding: const EdgeInsets.all(20),
                                    opacity: task.isCompleted ? 0.3 : 0.5,
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (task.id != null) {
                                              ref
                                                  .read(scheduleNotifierProvider.notifier)
                                                  .toggleTaskStatus(task.id!, task.isCompleted);
                                            }
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: task.isCompleted
                                                  ? AppColors.gold
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: task.isCompleted
                                                    ? AppColors.gold
                                                    : AppColors.textMuted.withValues(alpha: 0.3),
                                                width: 2,
                                              ),
                                              boxShadow: task.isCompleted
                                                  ? [
                                                      BoxShadow(
                                                          color: AppColors.gold.withValues(alpha: 0.35),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 4))
                                                    ]
                                                  : [],
                                            ),
                                            child: task.isCompleted
                                                ? Icon(Icons.check_rounded,
                                                    color: AppColors.background, size: 20)
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                task.title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: task.isCompleted
                                                      ? AppColors.textMuted
                                                      : AppColors.textPrimary,
                                                  decoration: task.isCompleted
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                  decorationThickness: 2,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: task.isCompleted
                                                      ? AppColors.textMuted.withValues(alpha: 0.08)
                                                      : AppColors.gold.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: task.isCompleted
                                                        ? Colors.transparent
                                                        : AppColors.gold.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons.clock,
                                                      size: 12,
                                                      color: task.isCompleted
                                                          ? AppColors.textMuted
                                                          : AppColors.gold,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      task.time,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                        color: task.isCompleted
                                                            ? AppColors.textMuted
                                                            : AppColors.goldLight,
                                                        fontSize: 12,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
          ],
        ),
      ),
    );
  }
}