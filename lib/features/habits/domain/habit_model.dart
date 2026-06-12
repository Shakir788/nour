class HabitModel {
  final int? id;
  final int waterIntakeMl; 
  final bool gymAttended;  
  final int projectSessions; 
  final String gratitudeText; 
  final String? imagePath; 
  final String? audioPath; 
  final String? unlockDate; // ✨ NAYA: Time Capsule ki date ke liye
  final String date;

  HabitModel({
    this.id,
    this.waterIntakeMl = 0,
    this.gymAttended = false,
    this.projectSessions = 0,
    this.gratitudeText = '', 
    this.imagePath,
    this.audioPath,
    this.unlockDate,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'water_intake_ml': waterIntakeMl,
      'gym_attended': gymAttended ? 1 : 0,
      'project_sessions': projectSessions,
      'gratitude_text': gratitudeText, 
      'image_path': imagePath, 
      'audio_path': audioPath, 
      'unlock_date': unlockDate, // ✨ DB mein jayega
      'date': date,
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'],
      waterIntakeMl: map['water_intake_ml'] ?? 0,
      gymAttended: map['gym_attended'] == 1,
      projectSessions: map['project_sessions'] ?? 0,
      gratitudeText: map['gratitude_text'] ?? '', 
      imagePath: map['image_path'], 
      audioPath: map['audio_path'], 
      unlockDate: map['unlock_date'], 
      date: map['date'],
    );
  }
}