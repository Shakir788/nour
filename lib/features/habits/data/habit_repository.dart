import '../../../core/database/database_helper.dart';
import '../domain/habit_model.dart';

class HabitRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<HabitModel> getHabitsForDate(String date) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_habits',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isEmpty) {
      // Agar aaj ka data nahi hai, toh ek fresh record bana do
      final newHabit = HabitModel(date: date);
      await db.insert('daily_habits', newHabit.toMap());
      return newHabit;
    }

    return HabitModel.fromMap(maps.first);
  }

  Future<int> updateHabits(HabitModel habit) async {
    final db = await dbHelper.database;
    return await db.update(
      'daily_habits',
      habit.toMap(),
      where: 'date = ?',
      whereArgs: [habit.date],
    );
  }
}