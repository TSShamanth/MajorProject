class Subject {
  final String id;
  final String name;
  final String code;
  final String className;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.className,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      className: json['className'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'className': className,
    };
  }
}

class Student {
  final String id;
  final String name;
  final String usn;
  final String email;

  Student({
    required this.id,
    required this.name,
    required this.usn,
    required this.email,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      usn: json['usn'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'usn': usn,
      'email': email,
    };
  }
}

class AttendanceRecord {
  final String id;
  final String subjectId;
  final String studentId;
  final String date;
  final bool isPresent;
  final String remarks;

  AttendanceRecord({
    required this.id,
    required this.subjectId,
    required this.studentId,
    required this.date,
    required this.isPresent,
    this.remarks = '',
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      subjectId: json['subjectId'],
      studentId: json['studentId'],
      date: json['date'],
      isPresent: json['isPresent'],
      remarks: json['remarks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'studentId': studentId,
      'date': date,
      'isPresent': isPresent,
      'remarks': remarks,
    };
  }
}

class AttendanceSummary {
  final String studentId;
  final String studentName;
  final int totalClasses;
  final int classesPresent;
  final double attendancePercentage;

  AttendanceSummary({
    required this.studentId,
    required this.studentName,
    required this.totalClasses,
    required this.classesPresent,
    required this.attendancePercentage,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      studentId: json['studentId'],
      studentName: json['studentName'],
      totalClasses: json['totalClasses'],
      classesPresent: json['classesPresent'],
      attendancePercentage: (json['attendancePercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'totalClasses': totalClasses,
      'classesPresent': classesPresent,
      'attendancePercentage': attendancePercentage,
    };
  }
}
