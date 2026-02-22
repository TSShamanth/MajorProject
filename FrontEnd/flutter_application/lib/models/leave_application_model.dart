class LeaveApplication {
  final String id;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String professor;
  final String status;
  final DateTime? createdAt;
  final String? documentUrl;
  final String? studentId; // New field
  final String? studentName; // New field
  final String? rejectionReason; // New field

  LeaveApplication({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.professor,
    required this.status,
    this.createdAt,
    this.documentUrl,
    this.studentId, // New field in constructor
    this.studentName, // New field in constructor
    this.rejectionReason, // New field in constructor
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: (json['id'] is String ? json['id'] as String : ''),
      leaveType: (json['leaveType'] is String ? json['leaveType'] as String : ''),
      startDate: DateTime.parse(json['startDate'] is String ? json['startDate'] as String : ''),
      endDate: DateTime.parse(json['endDate'] is String ? json['endDate'] as String : ''),
      reason: (json['reason'] is String ? json['reason'] as String : ''),
      professor: (json['professorName'] is String ? json['professorName'] as String : ''),
      status: (json['status'] is String ? json['status'] as String : ''),
      createdAt: (json['createdAt'] is String ? DateTime.parse(json['createdAt'] as String) : null),
      documentUrl: (json['documentUrl'] is String ? json['documentUrl'] as String : null),
      studentId: (json['userId'] is String ? json['userId'] as String : null), // Assuming 'userId' is studentId
      studentName: (json['studentName'] is String ? json['studentName'] as String : null), // New field from JSON
      rejectionReason: (json['rejectionReason'] is String ? json['rejectionReason'] as String : null),
    );
  }
}
