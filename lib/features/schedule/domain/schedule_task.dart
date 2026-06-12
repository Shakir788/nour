class ScheduleTask {
  final int? id;
  final String title;
  final String time;
  final bool isCompleted;
  final String date; // Format: YYYY-MM-DD

  ScheduleTask({
    this.id,
    required this.title,
    required this.time,
    this.isCompleted = false,
    required this.date,
  });

  ScheduleTask copyWith({
    int? id,
    String? title,
    String? time,
    bool? isCompleted,
    String? date,
  }) {
    return ScheduleTask(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'is_completed': isCompleted ? 1 : 0, // DB stores bool as int
      'date': date,
    };
  }

  factory ScheduleTask.fromMap(Map<String, dynamic> map) {
    return ScheduleTask(
      id: map['id'],
      title: map['title'],
      time: map['time'],
      isCompleted: map['is_completed'] == 1,
      date: map['date'],
    );
  }
}