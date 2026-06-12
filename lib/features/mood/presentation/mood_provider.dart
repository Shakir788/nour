import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/mood_repository.dart';
import '../domain/mood_model.dart';

final moodRepositoryProvider = Provider((ref) => MoodRepository());

final moodNotifierProvider = StateNotifierProvider<MoodNotifier, MoodModel?>((ref) {
  return MoodNotifier(ref.read(moodRepositoryProvider));
});

class MoodNotifier extends StateNotifier<MoodModel?> {
  final MoodRepository _repository;

  MoodNotifier(this._repository) : super(null) {
    loadTodayMood();
  }

  String get _todayDate {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> loadTodayMood() async {
    final mood = await _repository.getMoodForDate(_todayDate);
    state = mood;
  }

  Future<void> setMood(String moodType) async {
    final newMood = MoodModel(moodType: moodType, date: _todayDate);
    await _repository.saveMood(newMood);
    await loadTodayMood();
  }
}