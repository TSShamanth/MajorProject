class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? name;
  final String? usn;
  final String? phone;
  final String? sem;
  final String? departmentId; // Added departmentId
  final String? mentorName;
  final String? photoUrl;
  final String? programme;
  final String? school;
  final String? address;
  final String? dob;
  final String? bloodGroup;
  final String? emergencyContact;
  final String? validUpto;
  final List<String>? enrolledCourseCodes; // For students
  final List<String>? assignedCourseCodes; // For faculty
  final String? attendanceStatus;
  final String? activeLogId;
  final bool? isDetained;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.name,
    this.usn,
    this.phone,
    this.sem,
    this.departmentId,
    this.mentorName,
    this.photoUrl,
    this.programme,
    this.school,
    this.address,
    this.dob,
    this.bloodGroup,
    this.emergencyContact,
    this.validUpto,
    this.enrolledCourseCodes,
    this.assignedCourseCodes,
    this.attendanceStatus,
    this.activeLogId,
    this.isDetained,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final String uid = json['uid'] as String;
    final String email = json['email'] as String;
    final String displayName = (json['displayName'] ?? json['displayname'] ?? '') as String;
    final String role = json['role'] as String;

    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      name: json['name'] as String?,
      usn: json['usn'] as String?,
      phone: json['phone'] as String?,
      sem: json['sem'] as String?,
      departmentId: json['departmentId'] as String?,
      mentorName: json['mentorName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      programme: json['programme'] as String?,
      school: json['school'] as String?,
      address: json['address'] as String?,
      dob: json['dob'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      validUpto: json['validUpto'] as String?,
      enrolledCourseCodes: (json['enrolledCourseCodes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      assignedCourseCodes: (json['assignedCourseCodes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      attendanceStatus: json['attendanceStatus'] as String?,
      activeLogId: json['activeLogId'] as String?,
      isDetained: json['isDetained'] as bool?,
    );
  }
}
