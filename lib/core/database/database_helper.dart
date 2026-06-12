import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nour_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // ✨ VERSION 4 UPDATE (Time Capsule ke liye)
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // ✨ MIGRATION LOGIC
    );
  }

  // ✨ NAYA MIGRATION FUNCTION
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 1 se 2: Gratitude Text
      await db.execute("ALTER TABLE daily_habits ADD COLUMN gratitude_text TEXT DEFAULT '';");
    }
    if (oldVersion < 3) {
      // Version 2 se 3: Image aur Audio paths
      await db.execute("ALTER TABLE daily_habits ADD COLUMN image_path TEXT;");
      await db.execute("ALTER TABLE daily_habits ADD COLUMN audio_path TEXT;");
    }
    if (oldVersion < 4) {
      // ✨ Version 3 se 4: Time Capsule Lock Date
      await db.execute("ALTER TABLE daily_habits ADD COLUMN unlock_date TEXT;");
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // 1. Schedule Tasks Table
    await db.execute('''
    CREATE TABLE schedule_tasks (
      id $idType,
      title $textType,
      time $textType,
      is_completed $boolType,
      date $textType
    )
    ''');

    // 2. Prayer Tracker Table
    await db.execute('''
    CREATE TABLE prayer_tracker (
      id $idType,
      prayer_name $textType,
      is_completed $boolType,
      date $textType
    )
    ''');

    // 3. Quran Progress Table
    await db.execute('''
    CREATE TABLE quran_progress (
      id $idType,
      surah_name $textType,
      pages_read $intType,
      date $textType
    )
    ''');

    // 4. Daily Habits Table (Water, Gym, Project, Gratitude, Image, Audio, Unlock Date)
    await db.execute('''
    CREATE TABLE daily_habits (
      id $idType,
      water_intake_ml $intType,
      gym_attended $boolType,
      project_sessions $intType,
      gratitude_text TEXT DEFAULT '', 
      image_path TEXT,  
      audio_path TEXT,  
      unlock_date TEXT, -- ✨ Naya: Time Capsule Date ke liye
      date $textType
    )
    ''');

    // 5. Mood Tracker Table
    await db.execute('''
    CREATE TABLE mood_tracker (
      id $idType,
      mood_type $textType,
      date $textType
    )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}