import '../../../core/database/database_helper.dart';
import '../domain/mood_model.dart';

class MoodRepository {
  final dbHelper = DatabaseHelper.instance;

  // Aaj ka mood laane ke liye
  Future<MoodModel?> getMoodForDate(String date) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_tracker',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isEmpty) return null;
    return MoodModel.fromMap(maps.first);
  }

  // Naya mood save ya update karne ke liye
  Future<void> saveMood(MoodModel mood) async {
    final db = await dbHelper.database;
    final existingMood = await getMoodForDate(mood.date);

    if (existingMood == null) {
      // Aaj koi mood nahi dala, toh insert karo
      await db.insert('mood_tracker', mood.toMap());
    } else {
      // Update karo (agar din mein mood change kiya)
      await db.update(
        'mood_tracker',
        {'mood_type': mood.moodType},
        where: 'date = ?',
        whereArgs: [mood.date],
      );
    }
  }
}