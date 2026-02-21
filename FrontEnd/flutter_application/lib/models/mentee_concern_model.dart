class MenteeConcern {
  final String? id;
  final String studentId;
  final String mentorId;
  final String concernType; // 'Academic', 'Personal', 'Placement', 'Attendance'
  final String description;
  final String? mentorRemarks;
  final String priority; // 'Low', 'Medium', 'High'
  final String status; // 'Raised', 'Under Review', 'Resolved'
  final DateTime createdAt;
  final List<String> attachments;

  MenteeConcern({
    this.id,
    required this.studentId,
    required this.mentorId,
    required this.concernType,
    required this.description,
    this.mentorRemarks,
    this.priority = 'Medium',
    this.status = 'Raised',
    required this.createdAt,
    this.attachments = const [],
  });

  factory MenteeConcern.fromJson(Map<String, dynamic> json) {
    return MenteeConcern(
      id: json['id'],
      studentId: json['studentId'],
      mentorId: json['mentorId'],
      concernType: json['concernType'] ?? 'Academic',
      description: json['description'] ?? '',
      mentorRemarks: json['mentorRemarks'],
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'Raised',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      attachments: (json['attachments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'mentorId': mentorId,
      'concernType': concernType,
      'description': description,
      'mentorRemarks': mentorRemarks,
      'priority': priority,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'attachments': attachments,
    };
  }
}
