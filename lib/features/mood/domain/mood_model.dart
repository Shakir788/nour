class MoodModel {
  final int? id;
  final String moodType; // Happy, Calm, Tired, Sad, Stressed
  final String date;

  MoodModel({
    this.id,
    required this.moodType,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood_type': moodType,
      'date': date,
    };
  }

  factory MoodModel.fromMap(Map<String, dynamic> map) {
    return MoodModel(
      id: map['id'],
      moodType: map['mood_type'],
      date: map['date'],
    );
  }
}