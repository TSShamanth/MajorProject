class ExamScheduleEntry {
  final String date;
  final String startTime;
  final String endTime;
  final String duration;

  ExamScheduleEntry({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  factory ExamScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ExamScheduleEntry(
      date: json['date'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
    };
  }
}
