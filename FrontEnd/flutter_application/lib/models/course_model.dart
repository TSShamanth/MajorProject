class Course {
  final String courseCode;
  final String courseName;
  final String facultyUid;
  final String institutionId;
  final String program;
  final String semester;
  final List<String> studentsEnrolled;
  final String totalClasses;

  Course({
    required this.courseCode,
    required this.courseName,
    required this.facultyUid,
    required this.institutionId,
    required this.program,
    required this.semester,
    required this.studentsEnrolled,
    required this.totalClasses,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseCode: json['courseCode'],
      courseName: json['courseName'],
      facultyUid: json['facultyUid'],
      institutionId: json['institutionId'],
      program: json['program'],
      semester: json['semester'],
      studentsEnrolled: List<String>.from(json['studentsEnrolled']),
      totalClasses: json['totalClasses'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'facultyUid': facultyUid,
      'institutionId': institutionId,
      'program': program,
      'semester': semester,
      'studentsEnrolled': studentsEnrolled,
      'totalClasses': totalClasses,
    };
  }
}
