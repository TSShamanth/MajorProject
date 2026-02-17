class RegularisationRequest {
  final String id;
  final String facultyId;
  final String institutionId;
  final DateTime requestDate;
  final DateTime targetDate;
  final String? targetTime;
  final String? type;
  final String? newClockInTime;
  final String? newClockOutTime;
  final String reason;
  final String status;
  final String? approvedBy;
  final DateTime? approvedOn;
  final String? attendanceLogId;

  RegularisationRequest({
    required this.id,
    required this.facultyId,
    required this.institutionId,
    required this.requestDate,
    required this.targetDate,
    this.targetTime,
    this.type,
    this.newClockInTime,
    this.newClockOutTime,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.approvedOn,
    this.attendanceLogId,
  });

  factory RegularisationRequest.fromJson(Map<String, dynamic> json) {
    return RegularisationRequest(
      id: json['id'],
      facultyId: json['facultyId'],
      institutionId: json['institutionId'],
      requestDate: DateTime.parse(json['requestDate']),
      targetDate: DateTime.parse(json['targetDate']),
      targetTime: json['targetTime'],
      type: json['type'],
      newClockInTime: json['newClockInTime'],
      newClockOutTime: json['newClockOutTime'],
      reason: json['reason'],
      status: json['status'],
      approvedBy: json['approvedBy'],
      approvedOn: json['approvedOn'] != null ? DateTime.parse(json['approvedOn']) : null,
      attendanceLogId: json['attendanceLogId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facultyId': facultyId,
      'institutionId': institutionId,
      'requestDate': requestDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'targetTime': targetTime,
      'type': type,
      'newClockInTime': newClockInTime,
      'newClockOutTime': newClockOutTime,
      'reason': reason,
      'status': status,
      'approvedBy': approvedBy,
      'approvedOn': approvedOn?.toIso8601String(),
      'attendanceLogId': attendanceLogId,
    };
  }
}
