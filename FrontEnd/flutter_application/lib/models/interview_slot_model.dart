class InterviewSlotModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String companyName;
  final String driveId;
  final String roundName;
  final String dateTime;
  final String location;
  final String panelName;
  final String status;

  InterviewSlotModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.companyName,
    required this.driveId,
    required this.roundName,
    required this.dateTime,
    required this.location,
    required this.panelName,
    required this.status,
  });

  factory InterviewSlotModel.fromJson(Map<String, dynamic> json) {
    return InterviewSlotModel(
      id: json['id'] ?? '',
      studentUid: json['studentUid'] ?? '',
      studentName: json['studentName'] ?? '',
      companyName: json['companyName'] ?? '',
      driveId: json['driveId'] ?? '',
      roundName: json['roundName'] ?? '',
      dateTime: json['dateTime'] ?? '',
      location: json['location'] ?? '',
      panelName: json['panelName'] ?? '',
      status: json['status'] ?? 'Scheduled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentUid': studentUid,
      'studentName': studentName,
      'companyName': companyName,
      'driveId': driveId,
      'roundName': roundName,
      'dateTime': dateTime,
      'location': location,
      'panelName': panelName,
      'status': status,
    };
  }
}
