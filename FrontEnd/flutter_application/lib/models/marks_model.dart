class MarksModel {
  final String? id;
  final String? assessmentId;
  final String studentId;
  final String courseCode;
  final String institutionId;
  final String semester;
  final String type; // "Assignment", "Internal Test", "Project", "Final Exam"
  final String title;
  final double obtainedMarks;
  final double totalMarks;
  final String? examId;
  final int timestamp;

  MarksModel({
    this.id,
    this.assessmentId,
    required this.studentId,
    required this.courseCode,
    required this.institutionId,
    required this.semester,
    required this.type,
    required this.title,
    required this.obtainedMarks,
    required this.totalMarks,
    this.examId,
    required this.timestamp,
  });

  factory MarksModel.fromJson(Map<String, dynamic> json) {
    return MarksModel(
      id: json['id'],
      assessmentId: json['assessmentId'],
      studentId: json['studentId'] ?? '',
      courseCode: json['courseCode'] ?? '',
      institutionId: json['institutionId'] ?? '',
      semester: json['semester'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      obtainedMarks: (json['obtainedMarks'] as num?)?.toDouble() ?? 0.0,
      totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 0.0,
      examId: json['examId'],
      timestamp: json['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assessmentId': assessmentId,
      'studentId': studentId,
      'courseCode': courseCode,
      'institutionId': institutionId,
      'semester': semester,
      'type': type,
      'title': title,
      'obtainedMarks': obtainedMarks,
      'totalMarks': totalMarks,
      'examId': examId,
      'timestamp': timestamp,
    };
  }
}
