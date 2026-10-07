import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_model.dart';
import '../../../core/services/notification_service.dart';

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
    
    // ✨ SMART CLEANER LOGIC (Auto-Delete Past Tasks)
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<ScheduleModel> validTasks = [];

    for (var task in tasks) {
      // Agar task ki date aaj se purani hai (jaise kal ya parso ka task), 
      // toh usko permanently database aur system se delete kar do.
      if (task.date.compareTo(todayStr) < 0) {
        if (task.id != null) {
          await _repository.deleteTask(task.id!);
          await NotificationService.cancelRoutineTask(task.id!);
        }
      } else {
        // Agar task aaj ka hai ya future ka hai, toh usko list mein rakho
        validTasks.add(task);
      }
    }

    // Time ke hisaab se tasks ko sort karenge (Subah wale pehle, raat wale baad mein)
    validTasks.sort((a, b) => a.time.compareTo(b.time));
    state = validTasks;
  }

  Future<void> toggleTaskStatus(int id, bool currentStatus) async {
    await _repository.updateTaskStatus(id, !currentStatus);
    await loadTasks();
  }

  // ✨ Ab ye function us date par task save karega aur NOTIFICATION bhi lagayega
  Future<void> addTask(String time, String title, String date) async {
    final newTask = ScheduleModel(time: time, title: title, date: date);
    
    final insertedId = await _repository.insertTask(newTask); 
    await NotificationService.scheduleRoutineTask(insertedId, title, time, date);

    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    await NotificationService.cancelRoutineTask(id); 
    await loadTasks();
  }
}