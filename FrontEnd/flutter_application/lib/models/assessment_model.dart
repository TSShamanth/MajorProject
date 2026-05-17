class AssessmentModel {
  final String? id;
  final String institutionId;
  final String courseCode;
  final String semester;
  final String type;
  final String title;
  final double maxMarks;
  final double weightage;
  final int date;
  final String? createdBy;
  final String? instructions;
  final String? markingScheme;
  final bool isSubmissionRequired;

  AssessmentModel({
    this.id,
    required this.institutionId,
    required this.courseCode,
    required this.semester,
    required this.type,
    required this.title,
    required this.maxMarks,
    required this.weightage,
    required this.date,
    this.createdBy,
    this.instructions,
    this.markingScheme,
    this.isSubmissionRequired = false,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: json['id'],
      institutionId: json['institutionId'] ?? '',
      courseCode: json['courseCode'] ?? '',
      semester: json['semester'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      maxMarks: (json['maxMarks'] as num?)?.toDouble() ?? 0.0,
      weightage: (json['weightage'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] ?? 0,
      createdBy: json['createdBy'],
      instructions: json['instructions'],
      markingScheme: json['markingScheme'],
      isSubmissionRequired: json['isSubmissionRequired'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institutionId': institutionId,
      'courseCode': courseCode,
      'semester': semester,
      'type': type,
      'title': title,
      'maxMarks': maxMarks,
      'weightage': weightage,
      'date': date,
      'createdBy': createdBy,
      'instructions': instructions,
      'markingScheme': markingScheme,
      'isSubmissionRequired': isSubmissionRequired,
    };
  }
}
