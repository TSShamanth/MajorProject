import 'package:flutter_application/models/exam_schedule_entry.dart';
import 'package:flutter_application/models/room_model.dart';
import 'package:flutter_application/models/seating_entry.dart';

class HallTicketData {
  final String studentId;
  final String studentName;
  final String? studentUsn;
  final String? studentDepartment; // This is departmentId
  final String? studentSemester;

  final String examId;
  final String examName;
  final String examDepartmentId; // Department for which the exam is conducted
  final String examSemester; // Semester for which the exam is conducted
  final List<String> subjects;
  final Map<String, ExamScheduleEntry> schedule;
  final Map<String, SeatingEntry>? seatingArrangement; // Seating for all students in this exam
  final SeatingEntry studentSeatingEntry; // Specific seating for this student

  final Room studentRoomDetails; // Details of the room assigned to the student

  HallTicketData({
    required this.studentId,
    required this.studentName,
    this.studentUsn,
    this.studentDepartment,
    this.studentSemester,
    required this.examId,
    required this.examName,
    required this.examDepartmentId,
    required this.examSemester,
    required this.subjects,
    required this.schedule,
    this.seatingArrangement,
    required this.studentSeatingEntry,
    required this.studentRoomDetails,
  });

  factory HallTicketData.fromJson(Map<String, dynamic> json) {
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

    return HallTicketData(
      studentId: json['studentId'],
      studentName: json['studentName'],
      studentUsn: json['studentUsn'],
      studentDepartment: json['studentDepartment'],
      studentSemester: json['studentSemester'],
      examId: json['examId'],
      examName: json['examName'],
      examDepartmentId: json['examDepartmentId'],
      examSemester: json['examSemester'],
      subjects: List<String>.from(json['subjects']),
      schedule: deserializedSchedule,
      seatingArrangement: deserializedSeatingArrangement.isEmpty ? null : deserializedSeatingArrangement,
      studentSeatingEntry: SeatingEntry.fromJson(json['studentSeatingEntry']),
      studentRoomDetails: Room.fromJson(json['studentRoomDetails']),
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
      'studentId': studentId,
      'studentName': studentName,
      'studentUsn': studentUsn,
      'studentDepartment': studentDepartment,
      'studentSemester': studentSemester,
      'examId': examId,
      'examName': examName,
      'examDepartmentId': examDepartmentId,
      'examSemester': examSemester,
      'subjects': subjects,
      'schedule': serializedSchedule,
      'seatingArrangement': serializedSeatingArrangement,
      'studentSeatingEntry': studentSeatingEntry.toJson(),
      'studentRoomDetails': studentRoomDetails.toJson(),
    };
  }
}
