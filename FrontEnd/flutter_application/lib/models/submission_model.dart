class SubmissionModel {
  final String? id;
  final String assessmentId;
  final String studentId;
  final String studentName;
  final String fileUrl;
  final String fileName;
  final int submittedAt;
  final String status;
  final double marksObtained;
  final String? feedback;

  SubmissionModel({
    this.id,
    required this.assessmentId,
    required this.studentId,
    required this.studentName,
    required this.fileUrl,
    required this.fileName,
    required this.submittedAt,
    this.status = 'Submitted',
    this.marksObtained = 0.0,
    this.feedback,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'],
      assessmentId: json['assessmentId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileName: json['fileName'] ?? '',
      submittedAt: json['submittedAt'] ?? 0,
      status: json['status'] ?? 'Submitted',
      marksObtained: (json['marksObtained'] as num?)?.toDouble() ?? 0.0,
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assessmentId': assessmentId,
      'studentId': studentId,
      'studentName': studentName,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'submittedAt': submittedAt,
      'status': status,
      'marksObtained': marksObtained,
      'feedback': feedback,
    };
  }
}
