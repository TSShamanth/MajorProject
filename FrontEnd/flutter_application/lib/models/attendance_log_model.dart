import 'package:intl/intl.dart';

class AttendanceLog {
  final String id;
  final String facultyId;
  final String institutionId;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final int? duration; // in minutes
  final String? locationStatus; // e.g., "On-Campus", "Off-Campus"
  final String? locationDetail; // e.g., "RVU Campus" or "Lat: 12.9, Lon: 77.4"
  
  // Location coordinates are also available if needed for other features
  final double? clockInLatitude;
  final double? clockInLongitude;
  final double? clockOutLatitude;
  final double? clockOutLongitude;


  AttendanceLog({
    required this.id,
    required this.facultyId,
    required this.institutionId,
    required this.clockInTime,
    this.clockOutTime,
    this.duration,
    this.locationStatus,
    this.locationDetail,
    this.clockInLatitude,
    this.clockInLongitude,
    this.clockOutLatitude,
    this.clockOutLongitude,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'] as String,
      facultyId: json['facultyId'] as String,
      institutionId: json['institutionId'] as String,
      clockInTime: DateTime.parse(json['clockInTime'] as String),
      clockOutTime: json['clockOutTime'] != null ? DateTime.parse(json['clockOutTime'] as String) : null,
      duration: json['duration'] as int?,
      locationStatus: json['locationStatus'] as String?,
      locationDetail: json['locationDetail'] as String?,
      clockInLatitude: (json['clockInLatitude'] as num?)?.toDouble(),
      clockInLongitude: (json['clockInLongitude'] as num?)?.toDouble(),
      clockOutLatitude: (json['clockOutLatitude'] as num?)?.toDouble(),
      clockOutLongitude: (json['clockOutLongitude'] as num?)?.toDouble(),
    );
  }

  // Helper for displaying date
  String get formattedDate => DateFormat('MMM dd, yyyy').format(clockInTime);
  String get formattedClockInTime => DateFormat('hh:mm a').format(clockInTime);
  String get formattedClockOutTime => clockOutTime != null ? DateFormat('hh:mm a').format(clockOutTime!) : 'N/A';
  String get formattedDuration => duration != null ? '${duration! ~/ 60}h ${duration! % 60}m' : 'N/A';
}
