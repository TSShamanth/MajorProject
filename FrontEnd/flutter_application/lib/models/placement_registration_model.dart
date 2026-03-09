class PlacementRegistrationModel {
  final String uid;
  final String resumeUrl;
  final String photoUrl;
  final double cgpa;
  final List<String> skills;
  final int backlogCount;
  final List<String> interestedDepartments;
  final String? registrationDate;

  PlacementRegistrationModel({
    required this.uid,
    required this.resumeUrl,
    required this.photoUrl,
    required this.cgpa,
    required this.skills,
    required this.backlogCount,
    required this.interestedDepartments,
    this.registrationDate,
  });

  factory PlacementRegistrationModel.fromJson(Map<String, dynamic> json) {
    return PlacementRegistrationModel(
      uid: json['uid'] as String,
      resumeUrl: json['resumeUrl'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      backlogCount: json['backlogCount'] as int? ?? 0,
      interestedDepartments: (json['interestedDepartments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      registrationDate: json['registrationDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'resumeUrl': resumeUrl,
      'photoUrl': photoUrl,
      'cgpa': cgpa,
      'skills': skills,
      'backlogCount': backlogCount,
      'interestedDepartments': interestedDepartments,
      'registrationDate': registrationDate,
    };
  }
}
