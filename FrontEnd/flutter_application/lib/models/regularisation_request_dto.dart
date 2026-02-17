class RegularisationRequestDTO {
  final DateTime targetDate;
  final String? targetTime; // e.g., "09:30" - for missed entry
  final String? type; // "Clock-in" or "Clock-out" - for missed entry
  final String? newClockInTime;
  final String? newClockOutTime;
  final String reason;
  final String? attendanceLogId;

  RegularisationRequestDTO({
    required this.targetDate,
    this.targetTime,
    this.type,
    this.newClockInTime,
    this.newClockOutTime,
    required this.reason,
    this.attendanceLogId,
  });

  Map<String, dynamic> toJson() {
    return {
      'targetDate': targetDate.toIso8601String(),
      'targetTime': targetTime,
      'type': type,
      'newClockInTime': newClockInTime,
      'newClockOutTime': newClockOutTime,
      'reason': reason,
      'attendanceLogId': attendanceLogId,
    };
  }
}
