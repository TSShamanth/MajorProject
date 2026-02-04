class SubjectWiseAttendance {
  final String courseName;
  final String courseCode;
  final String facultyName;
  final double attendancePercentage;
  final int totalClasses;
  final int attendedClasses;

  SubjectWiseAttendance({
    required this.courseName,
    required this.courseCode,
    required this.facultyName,
    required this.attendancePercentage,
    required this.totalClasses,
    required this.attendedClasses,
  });

  factory SubjectWiseAttendance.fromJson(Map<String, dynamic> json) {
    return SubjectWiseAttendance(
      courseName: json['courseName'],
      courseCode: json['courseCode'],
      facultyName: json['facultyName'],
      attendancePercentage: (json['attendancePercentage'] as num).toDouble(),
      totalClasses: json['totalClasses'],
      attendedClasses: json['attendedClasses'],
    );
  }
}
