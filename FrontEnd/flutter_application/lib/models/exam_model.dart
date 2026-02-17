import 'exam_schedule_entry.dart'; // Import the new ExamScheduleEntry model

class Exam {
  final String id;
  final String name;
  final String departmentId;
  final String semester;
  final List<String> subjects;
  final Map<String, ExamScheduleEntry> schedule; // New field for per-subject scheduling
  final List<String> frozenCandidateList; // New field for storing frozen eligible student UIDs

  Exam({
    required this.id,
    required this.name,
    required this.departmentId,
    required this.semester,
    required this.subjects,
    this.schedule = const {}, // Initialize with an empty map if not provided
    this.frozenCandidateList = const [], // Initialize with an empty list if not provided
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    // Deserialize schedule map
    Map<String, ExamScheduleEntry> deserializedSchedule = {};
    if (json['schedule'] != null) {
      (json['schedule'] as Map<String, dynamic>).forEach((key, value) {
        deserializedSchedule[key] = ExamScheduleEntry.fromJson(value as Map<String, dynamic>);
      });
    }

    return Exam(
      id: json['id'],
      name: json['name'],
      departmentId: json['departmentId'],
      semester: json['semester'],
      subjects: List<String>.from(json['subjects']),
      schedule: deserializedSchedule,
      frozenCandidateList: List<String>.from(json['frozenCandidateList'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    // Serialize schedule map
    Map<String, dynamic> serializedSchedule = {};
    schedule.forEach((key, value) {
      serializedSchedule[key] = value.toJson();
    });

    return {
      'id': id,
      'name': name,
      'departmentId': departmentId,
      'semester': semester,
      'subjects': subjects,
      'schedule': serializedSchedule,
      'frozenCandidateList': frozenCandidateList,
    };
  }
}
