class QuranModel {
  final int? id;
  final String surahName;
  final int pagesRead;
  final String date;

  QuranModel({
    this.id,
    required this.surahName,
    required this.pagesRead,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surah_name': surahName,
      'pages_read': pagesRead,
      'date': date,
    };
  }

  factory QuranModel.fromMap(Map<String, dynamic> map) {
    return QuranModel(
      id: map['id'],
      surahName: map['surah_name'],
      pagesRead: map['pages_read'],
      date: map['date'],
    );
  }
}