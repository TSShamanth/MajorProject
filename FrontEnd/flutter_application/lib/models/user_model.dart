class UserModel {
  final String uid;
  final String? email; // Made nullable
  final String displayName;
  final String? role; // Made nullable
  final List<String> userRoles; // Added to support multiple roles
  final String? name;
  final String? usn;
  final String? phone;
  final String? sem;
  final String? departmentId; // Added departmentId
  final String? sectionId; // Added sectionId
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
    this.userRoles = const [], // Default to empty list
    this.name,
    this.usn,
    this.phone,
    this.sem,
    this.departmentId,
    this.sectionId,
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
    final String? email = json['email'] as String?; // Cast as String?
    final String displayName = (json['displayName'] ?? json['displayname'] ?? '') as String;
    final String? role = json['role'] as String?; // Cast as String?
    final List<String> userRoles = (json['userRoles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? []; // Handle multiple roles

    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      userRoles: userRoles,
      name: json['name'] as String?,
      usn: json['usn'] as String?,
      phone: json['phone'] as String?,
      sem: json['sem'] as String?,
      departmentId: json['departmentId'] as String?,
      sectionId: json['sectionId'] as String?,
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

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'userRoles': userRoles, // Include userRoles in JSON output
      'name': name,
      'usn': usn,
      'phone': phone,
      'sem': sem,
      'departmentId': departmentId,
      'sectionId': sectionId,
      'mentorName': mentorName,
      'photoUrl': photoUrl,
      'programme': programme,
      'school': school,
      'address': address,
      'dob': dob,
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'validUpto': validUpto,
      'enrolledCourseCodes': enrolledCourseCodes,
      'assignedCourseCodes': assignedCourseCodes,
      'attendanceStatus': attendanceStatus,
      'activeLogId': activeLogId,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    List<String>? userRoles, // Allow copying with new userRoles
    String? name,
    String? usn,
    String? phone,
    String? sem,
    String? departmentId,
    String? sectionId,
    String? mentorName,
    String? photoUrl,
    String? programme,
    String? school,
    String? address,
    String? dob,
    String? bloodGroup,
    String? emergencyContact,
    String? validUpto,
    List<String>? enrolledCourseCodes,
    List<String>? assignedCourseCodes,
    String? attendanceStatus,
    String? activeLogId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      userRoles: userRoles ?? this.userRoles, // Apply new userRoles during copy
      name: name ?? this.name,
      usn: usn ?? this.usn,
      phone: phone ?? this.phone,
      sem: sem ?? this.sem,
      departmentId: departmentId ?? this.departmentId,
      sectionId: sectionId ?? this.sectionId,
      mentorName: mentorName ?? this.mentorName,
      photoUrl: photoUrl ?? this.photoUrl,
      programme: programme ?? this.programme,
      school: school ?? this.school,
      address: address ?? this.address,
      dob: dob ?? this.dob,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      validUpto: validUpto ?? this.validUpto,
      enrolledCourseCodes: enrolledCourseCodes ?? this.enrolledCourseCodes,
      assignedCourseCodes: assignedCourseCodes ?? this.assignedCourseCodes,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      activeLogId: activeLogId ?? this.activeLogId,
    );
  }
}