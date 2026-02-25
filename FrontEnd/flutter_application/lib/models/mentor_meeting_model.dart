class MentorMeeting {
  final String? id;
  final String mentorId;
  final String studentId;
  final String studentName;
  final DateTime date;
  final String notes;
  final String followUpAction;
  final List<Map<String, dynamic>> actionItems;
  final String status; // 'Requested', 'Approved', 'Completed', 'Cancelled'
  final String mode; // 'Online', 'Offline'
  final List<String> attachments;

  MentorMeeting({
    this.id,
    required this.mentorId,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.notes,
    required this.followUpAction,
    this.actionItems = const [],
    this.status = 'Scheduled',
    this.mode = 'Offline',
    this.attachments = const [],
  });

  factory MentorMeeting.fromJson(Map<String, dynamic> json) {
    return MentorMeeting(
      id: json['id'],
      mentorId: json['mentorId'],
      studentId: json['studentId'],
      studentName: json['studentName'] ?? '',
      date: DateTime.parse(json['date']),
      notes: json['notes'] ?? '',
      followUpAction: json['followUpAction'] ?? '',
      actionItems: (json['actionItems'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      status: json['status'] ?? 'Scheduled',
      mode: json['mode'] ?? 'Offline',
      attachments: (json['attachments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mentorId': mentorId,
      'studentId': studentId,
      'studentName': studentName,
      'date': date.toIso8601String(),
      'notes': notes,
      'followUpAction': followUpAction,
      'actionItems': actionItems,
      'status': status,
      'mode': mode,
      'attachments': attachments,
    };
  }
}
