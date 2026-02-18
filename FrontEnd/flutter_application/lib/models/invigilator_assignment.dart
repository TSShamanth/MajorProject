class InvigilatorAssignment {
  final String id;
  final String examId;
  final String roomId;
  final String facultyId;
  final String institutionId;
  final String? session; // e.g., "Morning", "Afternoon", or could be tied to exam schedule entry

  InvigilatorAssignment({
    required this.id,
    required this.examId,
    required this.roomId,
    required this.facultyId,
    required this.institutionId,
    this.session,
  });

  factory InvigilatorAssignment.fromJson(Map<String, dynamic> json) {
    return InvigilatorAssignment(
      id: json['id'],
      examId: json['examId'],
      roomId: json['roomId'],
      facultyId: json['facultyId'],
      institutionId: json['institutionId'],
      session: json['session'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examId': examId,
      'roomId': roomId,
      'facultyId': facultyId,
      'institutionId': institutionId,
      'session': session,
    };
  }
}
