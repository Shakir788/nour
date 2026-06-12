class PrayerModel {
  final int? id;
  final String prayerName; // Fajr, Dhuhr, Asr, Maghreb, Isha
  final bool isCompleted;
  final String date;

  PrayerModel({
    this.id,
    required this.prayerName,
    this.isCompleted = false,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prayer_name': prayerName,
      'is_completed': isCompleted ? 1 : 0,
      'date': date,
    };
  }

  factory PrayerModel.fromMap(Map<String, dynamic> map) {
    return PrayerModel(
      id: map['id'],
      prayerName: map['prayer_name'],
      isCompleted: map['is_completed'] == 1,
      date: map['date'],
    );
  }
}