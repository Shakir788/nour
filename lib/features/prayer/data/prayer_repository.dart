import '../../../core/database/database_helper.dart';

// ✨ Is file ke andar hi model define kar diya taaki import ka koi lafda hi na ho!
class PrayerModel {
  final int? id;
  final String prayerName;
  final String date;
  final bool isCompleted;

  PrayerModel({
    this.id,
    required this.prayerName,
    required this.date,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prayer_name': prayerName,
      'date': date,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory PrayerModel.fromMap(Map<String, dynamic> map) {
    return PrayerModel(
      id: map['id'],
      prayerName: map['prayer_name'],
      date: map['date'],
      isCompleted: map['is_completed'] == 1,
    );
  }
}

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
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']; // ✨ Maghreb ko Maghrib kar diya Global standard ke hisab se
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