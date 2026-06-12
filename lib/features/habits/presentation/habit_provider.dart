import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/habit_repository.dart';
import '../domain/habit_model.dart';

final habitRepositoryProvider = Provider((ref) => HabitRepository());

final habitNotifierProvider = StateNotifierProvider<HabitNotifier, HabitModel?>((ref) {
  return HabitNotifier(ref.read(habitRepositoryProvider));
});

class HabitNotifier extends StateNotifier<HabitModel?> {
  final HabitRepository _repository;

  HabitNotifier(this._repository) : super(null) {
    loadTodayHabits();
  }

  String get _todayDate {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> loadTodayHabits() async {
    final habits = await _repository.getHabitsForDate(_todayDate);
    state = habits;
  }

  // ✨ Helper method: Code ko clean rakhne aur Optimistic Update ke liye
  Future<void> _updateStateAndDb(HabitModel updatedHabit) async {
    state = updatedHabit; // ✨ UI Turant Update
    try {
      await _repository.updateHabits(updatedHabit); // Background save
    } catch (e) {
      print("DB Update Error: $e");
    }
  }

  Future<void> addWater(int ml) async {
    if (state == null) return;
    _updateStateAndDb(HabitModel(
      id: state!.id,
      waterIntakeMl: state!.waterIntakeMl + ml,
      gymAttended: state!.gymAttended,
      projectSessions: state!.projectSessions,
      gratitudeText: state!.gratitudeText,
      imagePath: state!.imagePath, 
      audioPath: state!.audioPath, 
      unlockDate: state!.unlockDate, // ✨ Safe
      date: state!.date,
    ));
  }

  Future<void> toggleGym(bool attended) async {
    if (state == null) return;
    _updateStateAndDb(HabitModel(
      id: state!.id,
      waterIntakeMl: state!.waterIntakeMl,
      gymAttended: attended,
      projectSessions: state!.projectSessions,
      gratitudeText: state!.gratitudeText,
      imagePath: state!.imagePath, 
      audioPath: state!.audioPath, 
      unlockDate: state!.unlockDate, // ✨ Safe
      date: state!.date,
    ));
  }

  Future<void> addProjectSession() async {
    if (state == null) return;
    _updateStateAndDb(HabitModel(
      id: state!.id,
      waterIntakeMl: state!.waterIntakeMl,
      gymAttended: state!.gymAttended,
      projectSessions: state!.projectSessions + 1,
      gratitudeText: state!.gratitudeText,
      imagePath: state!.imagePath, 
      audioPath: state!.audioPath, 
      unlockDate: state!.unlockDate, // ✨ Safe
      date: state!.date,
    ));
  }

  Future<void> updateGratitude(String text) async {
    if (state == null) return;
    _updateStateAndDb(HabitModel(
      id: state!.id,
      waterIntakeMl: state!.waterIntakeMl,
      gymAttended: state!.gymAttended,
      projectSessions: state!.projectSessions,
      gratitudeText: text,
      imagePath: state!.imagePath, 
      audioPath: state!.audioPath, 
      unlockDate: state!.unlockDate, // ✨ Safe
      date: state!.date,
    ));
  }

  Future<void> updateImage(String path) async {
    if (state == null) return;
    _updateStateAndDb(HabitModel(
      id: state!.id,
      waterIntakeMl: state!.waterIntakeMl,
      gymAttended: state!.gymAttended,
      projectSessions: state!.projectSessions,
      gratitudeText: state!.gratitudeText,
      imagePath: path,
      audioPath: state!.audioPath,
      unlockDate: state!.unlockDate, // ✨ Safe
      date: state!.date,
    ));
  }

  Future<void> updateAudio(String path) async {
    if (state == null) return;
    _updateStateAndDb(HabitModel(
      id: state!.id,
      waterIntakeMl: state!.waterIntakeMl,
      gymAttended: state!.gymAttended,
      projectSessions: state!.projectSessions,
      gratitudeText: state!.gratitudeText,
      imagePath: state!.imagePath,
      audioPath: path,
      unlockDate: state!.unlockDate, // ✨ Safe
      date: state!.date,
    ));
  }

  // ✨ NAYA METHOD: Time Capsule Date Save Karne Ke Liye
  Future<void> setUnlockDate(String lockedDate) async {
    if (state == null) return;
    _updateStateAndDb(HabitModel(
      id: state!.id,
      waterIntakeMl: state!.waterIntakeMl,
      gymAttended: state!.gymAttended,
      projectSessions: state!.projectSessions,
      gratitudeText: state!.gratitudeText,
      imagePath: state!.imagePath,
      audioPath: state!.audioPath,
      unlockDate: lockedDate, // ✨ Yahan Time Capsule ka data aayega
      date: state!.date,
    ));
  }
}