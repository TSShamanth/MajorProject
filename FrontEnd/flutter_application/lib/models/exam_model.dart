class Exam {
  final String id;
  final String name;
  final String departmentId;
  final String semester;
  final List<String> subjects;
  final String examDate;
  final String startTime;
  final String endTime;
  final String duration;

  Exam({
    required this.id,
    required this.name,
    required this.departmentId,
    required this.semester,
    required this.subjects,
    required this.examDate,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'],
      name: json['name'],
      departmentId: json['departmentId'],
      semester: json['semester'],
      subjects: List<String>.from(json['subjects']),
      examDate: json['examDate'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'departmentId': departmentId,
      'semester': semester,
      'subjects': subjects,
      'examDate': examDate,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
    };
  }
}
