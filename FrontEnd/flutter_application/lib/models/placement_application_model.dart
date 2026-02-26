class PlacementApplicationModel {
  final String id;
  final String driveId;
  final String studentUid;
  final String studentName;
  final String companyName;
  final String jobRole;
  final String currentRound;
  final String status; // 'Applied', 'Shortlisted', 'Selected', 'Rejected'
  final String appliedDate;

  PlacementApplicationModel({
    required this.id,
    required this.driveId,
    required this.studentUid,
    required this.studentName,
    required this.companyName,
    required this.jobRole,
    required this.currentRound,
    required this.status,
    required this.appliedDate,
  });

  factory PlacementApplicationModel.fromJson(Map<String, dynamic> json) {
    return PlacementApplicationModel(
      id: json['id'] ?? '',
      driveId: json['driveId'] ?? '',
      studentUid: json['studentUid'] ?? '',
      studentName: json['studentName'] ?? '',
      companyName: json['companyName'] ?? '',
      jobRole: json['jobRole'] ?? '',
      currentRound: json['currentRound'] ?? 'Registration',
      status: json['status'] ?? 'Applied',
      appliedDate: json['appliedDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driveId': driveId,
      'studentUid': studentUid,
      'studentName': studentName,
      'companyName': companyName,
      'jobRole': jobRole,
      'currentRound': currentRound,
      'status': status,
      'appliedDate': appliedDate,
    };
  }
}
