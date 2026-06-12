class ScheduleModel {
  final int? id;
  final String time;
  final String title;
  final bool isCompleted;
  final String date;

  ScheduleModel({
    this.id,
    required this.time,
    required this.title,
    this.isCompleted = false,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'date': date,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'],
      time: map['time'],
      title: map['title'],
      isCompleted: map['is_completed'] == 1,
      date: map['date'],
    );
  }
}