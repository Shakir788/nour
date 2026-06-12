import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_model.dart';

final scheduleRepositoryProvider = Provider((ref) => ScheduleRepository());

// ✨ Ye provider track karega ki screen par kaunsi date select ki gayi hai
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// ✨ Jab bhi selectedDate badlegi, ye provider automatically us date ke tasks load kar lega
final scheduleNotifierProvider = StateNotifierProvider<ScheduleNotifier, List<ScheduleModel>>((ref) {
  final repo = ref.read(scheduleRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return ScheduleNotifier(repo, selectedDate);
});

class ScheduleNotifier extends StateNotifier<List<ScheduleModel>> {
  final ScheduleRepository _repository;
  final DateTime _selectedDate;

  ScheduleNotifier(this._repository, this._selectedDate) : super([]) {
    loadTasks();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> loadTasks() async {
    final tasks = await _repository.getTasksForDate(_dateStr);
    // Time ke hisaab se tasks ko sort karenge (Subah wale pehle, raat wale baad mein)
    tasks.sort((a, b) => a.time.compareTo(b.time));
    state = tasks;
  }

  Future<void> toggleTaskStatus(int id, bool currentStatus) async {
    await _repository.updateTaskStatus(id, !currentStatus);
    await loadTasks();
  }

  // ✨ Ab ye function us date par task save karega jo user ne select ki hai
  Future<void> addTask(String time, String title, String date) async {
    final newTask = ScheduleModel(time: time, title: title, date: date);
    await _repository.insertTask(newTask);
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    await loadTasks();
  }
}