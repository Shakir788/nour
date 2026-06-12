// File: lib/features/prayer/data/prayer_model.dart

class PrayerDay {
  final String date;
  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;

  PrayerDay({
    required this.date,
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
  });

  factory PrayerDay.fromMap(Map<String, dynamic> map) {
    return PrayerDay(
      date: map['date'] as String,
      fajr: map['fajr'] == 1,
      dhuhr: map['dhuhr'] == 1,
      asr: map['asr'] == 1,
      maghrib: map['maghrib'] == 1,
      isha: map['isha'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'fajr': fajr ? 1 : 0,
      'dhuhr': dhuhr ? 1 : 0,
      'asr': asr ? 1 : 0,
      'maghrib': maghrib ? 1 : 0,
      'isha': isha ? 1 : 0,
    };
  }

  PrayerDay copyWith({
    String? date,
    bool? fajr,
    bool? dhuhr,
    bool? asr,
    bool? maghrib,
    bool? isha,
  }) {
    return PrayerDay(
      date: date ?? this.date,
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  double get completionPercentage {
    int count = 0;
    if (fajr) count++;
    if (dhuhr) count++;
    if (asr) count++;
    if (maghrib) count++;
    if (isha) count++;
    return count / 5.0;
  }
}