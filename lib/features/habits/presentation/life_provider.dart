// File: lib/features/habits/presentation/life_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ✨ 1. Habit Model
class Habit {
  final String id;
  final String title;
  final bool isCompleted;

  Habit({required this.id, required this.title, this.isCompleted = false});

  Habit copyWith({bool? isCompleted}) {
    return Habit(
      id: id,
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// ✨ 2. Daily Life Data Model (Mood, Habits, Gratitude)
class DailyLifeData {
  final String date;
  final String? mood; 
  final List<Habit> habits;
  final String gratitude;

  DailyLifeData({
    required this.date,
    this.mood,
    required this.habits,
    this.gratitude = '',
  });

  DailyLifeData copyWith({
    String? mood,
    List<Habit>? habits,
    String? gratitude,
  }) {
    return DailyLifeData(
      date: date,
      mood: mood ?? this.mood,
      habits: habits ?? this.habits,
      gratitude: gratitude ?? this.gratitude,
    );
  }
}

// ✨ 3. Life Notifier (State Management)
class LifeNotifier extends StateNotifier<Map<String, DailyLifeData>> {
  LifeNotifier() : super({});

  // Default Habits in French
  final List<Habit> _defaultHabits = [
    Habit(id: 'water', title: "Boire de l'eau 💧"),
    Habit(id: 'read', title: "Lire 10 pages 📖"),
    Habit(id: 'exercise', title: "Faire de l'exercice 🏃‍♀️"),
  ];

  // Data Read Karne ke liye
  DailyLifeData getLifeDataForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return state[dateStr] ?? DailyLifeData(date: dateStr, habits: List.from(_defaultHabits));
  }

  // Mood Update karna
  void updateMood(DateTime date, String mood) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final currentData = getLifeDataForDate(date);
    state = {...state, dateStr: currentData.copyWith(mood: mood)};
  }

  // Habit Tick/Untick karna
  void toggleHabit(DateTime date, String habitId) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final currentData = getLifeDataForDate(date);
    
    final updatedHabits = currentData.habits.map((h) {
      if (h.id == habitId) {
        return h.copyWith(isCompleted: !h.isCompleted);
      }
      return h;
    }).toList();

    state = {...state, dateStr: currentData.copyWith(habits: updatedHabits)};
  }

  // Journal (Gratitude) Text Save karna
  void updateGratitude(DateTime date, String text) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final currentData = getLifeDataForDate(date);
    state = {...state, dateStr: currentData.copyWith(gratitude: text)};
  }
}

// ✨ 4. Providers for UI
final lifeProvider = StateNotifierProvider<LifeNotifier, Map<String, DailyLifeData>>((ref) {
  return LifeNotifier();
});

// Calendar sync ke liye Date Provider
final selectedLifeDateProvider = StateProvider<DateTime>((ref) => DateTime.now());