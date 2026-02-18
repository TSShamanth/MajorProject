import 'exam_schedule_entry.dart';
import 'seating_entry.dart';

class Exam {
  final String id;
  final String name;
  final String departmentId;
  final String semester;
  final List<String> subjects;
  final Map<String, ExamScheduleEntry> schedule;
  final List<String>? frozenCandidateList;
  final Map<String, SeatingEntry>? seatingArrangement; // New field

  Exam({
    required this.id,
    required this.name,
    required this.departmentId,
    required this.semester,
    required this.subjects,
    this.schedule = const {},
    this.frozenCandidateList = const [],
    this.seatingArrangement, // Initialize with null if not provided
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    Map<String, ExamScheduleEntry> deserializedSchedule = {};
    if (json['schedule'] != null) {
      (json['schedule'] as Map<String, dynamic>).forEach((key, value) {
        deserializedSchedule[key] = ExamScheduleEntry.fromJson(value as Map<String, dynamic>);
      });
    }

    Map<String, SeatingEntry> deserializedSeatingArrangement = {};
    if (json['seatingArrangement'] != null) {
      (json['seatingArrangement'] as Map<String, dynamic>).forEach((key, value) {
        deserializedSeatingArrangement[key] = SeatingEntry.fromJson(value as Map<String, dynamic>);
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
      seatingArrangement: deserializedSeatingArrangement.isEmpty ? null : deserializedSeatingArrangement,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> serializedSchedule = {};
    schedule.forEach((key, value) {
      serializedSchedule[key] = value.toJson();
    });

    Map<String, dynamic>? serializedSeatingArrangement;
    if (seatingArrangement != null) {
      serializedSeatingArrangement = seatingArrangement!.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
    }

    return {
      'id': id,
      'name': name,
      'departmentId': departmentId,
      'semester': semester,
      'subjects': subjects,
      'schedule': serializedSchedule,
      'frozenCandidateList': frozenCandidateList,
      'seatingArrangement': serializedSeatingArrangement,
    };
  }
}
