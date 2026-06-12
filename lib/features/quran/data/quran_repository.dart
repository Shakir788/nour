import '../../../core/database/database_helper.dart';
import '../domain/quran_model.dart';

class QuranRepository {
  final dbHelper = DatabaseHelper.instance;

  // Saari reading history laane ke liye (Latest pehle)
  Future<List<QuranModel>> getAllReadings() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quran_progress',
      orderBy: 'id DESC', // Naya record upar dikhega
    );

    return List.generate(maps.length, (i) => QuranModel.fromMap(maps[i]));
  }

  // Nayi reading save karne ke liye
  Future<int> insertReading(QuranModel quranModel) async {
    final db = await dbHelper.database;
    return await db.insert('quran_progress', quranModel.toMap());
  }
}