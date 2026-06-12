import '../../../core/database/database_helper.dart';
import '../domain/schedule_model.dart';

class ScheduleRepository {
  final dbHelper = DatabaseHelper.instance;
  // ✨ Table ka naam database helper ke hisaab se theek kar diya
  final String tableName = 'schedule_tasks';

  Future<List<ScheduleModel>> getTasksForDate(String date) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isEmpty) return [];

    return List.generate(maps.length, (i) => ScheduleModel.fromMap(maps[i]));
  }

  Future<int> insertTask(ScheduleModel task) async {
    final db = await dbHelper.database;
    return await db.insert(tableName, task.toMap());
  }

  Future<int> updateTaskStatus(int id, bool isCompleted) async {
    final db = await dbHelper.database;
    return await db.update(
      tableName,
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}