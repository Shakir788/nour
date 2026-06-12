import '../../../core/database/database_helper.dart';
import '../domain/prayer_model.dart';

class PrayerRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<PrayerModel>> getPrayersForDate(String date) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prayer_tracker',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isEmpty) {
      await _seedDailyPrayers(date);
      return getPrayersForDate(date); 
    }

    return List.generate(maps.length, (i) => PrayerModel.fromMap(maps[i]));
  }

  Future<void> _seedDailyPrayers(String date) async {
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghreb', 'Isha'];
    for (var prayer in prayers) {
      await insertPrayer(PrayerModel(prayerName: prayer, date: date));
    }
  }

  Future<int> insertPrayer(PrayerModel prayer) async {
    final db = await dbHelper.database;
    return await db.insert('prayer_tracker', prayer.toMap());
  }

  Future<int> updatePrayerStatus(int id, bool isCompleted) async {
    final db = await dbHelper.database;
    return await db.update(
      'prayer_tracker',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}