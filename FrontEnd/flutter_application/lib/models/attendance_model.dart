class AttendanceModel {
  String? id; // Unique ID for each attendance record
  String courseCode;
  String studentUid;
  String date; // Stored as yyyy-MM-dd string
  String status; // e.g., "Present", "Absent", "Late"
  String? remarks; // Optional remarks
  String? facultyUid; // Who marked the attendance
  String institutionId;
  String? departmentId;

  AttendanceModel({
    this.id,
    required this.courseCode,
    required this.studentUid,
    required this.date,
    required this.status,
    this.remarks,
    this.facultyUid,
    required this.institutionId,
    this.departmentId,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      courseCode: json['courseCode'],
      studentUid: json['studentUid'],
      date: json['date'],
      status: json['status'],
      remarks: json['remarks'],
      facultyUid: json['facultyUid'],
      institutionId: json['institutionId'],
      departmentId: json['departmentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseCode': courseCode,
      'studentUid': studentUid,
      'date': date,
      'status': status,
      'remarks': remarks,
      'facultyUid': facultyUid,
      'institutionId': institutionId,
      'departmentId': departmentId,
    };
  }
}
