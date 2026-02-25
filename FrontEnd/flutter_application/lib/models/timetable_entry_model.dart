class TimetableEntry {
  final String? id;
  final String institutionId;
  final String departmentId;
  final String program;
  final String semester;
  final String sectionId;
  final String day;
  final String timeSlotId;
  final String courseCode;
  final String facultyUid;
  final String roomId;
  final String academicYear;

  TimetableEntry({
    this.id,
    required this.institutionId,
    required this.departmentId,
    required this.program,
    required this.semester,
    required this.sectionId,
    required this.day,
    required this.timeSlotId,
    required this.courseCode,
    required this.facultyUid,
    required this.roomId,
    required this.academicYear,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'],
      institutionId: json['institutionId'],
      departmentId: json['departmentId'],
      program: json['program'],
      semester: json['semester'],
      sectionId: json['sectionId'],
      day: json['day'],
      timeSlotId: json['timeSlotId'],
      courseCode: json['courseCode'],
      facultyUid: json['facultyUid'],
      roomId: json['roomId'],
      academicYear: json['academicYear'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institutionId': institutionId,
      'departmentId': departmentId,
      'program': program,
      'semester': semester,
      'sectionId': sectionId,
      'day': day,
      'timeSlotId': timeSlotId,
      'courseCode': courseCode,
      'facultyUid': facultyUid,
      'roomId': roomId,
      'academicYear': academicYear,
    };
  }
}
