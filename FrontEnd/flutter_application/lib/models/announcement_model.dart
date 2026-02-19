
class AnnouncementModel {
  final String id;
  final String institutionId;
  final String title;
  final String description;
  final String? content;
  final String createdBy;
  final String createdByName;
  final String createdByRole;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledFor;
  final bool isActive;
  final List<String> targetAudience; // ['admin', 'faculty', 'student', 'alumni']
  final List<String> targetDepartments; // Empty means all departments
  final List<String> attachmentUrls;
  final int? priority; // 1 = Low, 2 = Medium, 3 = High
  final String? category; // 'general', 'academic', 'event', 'urgent'
  final bool isPinned; // Add isPinned field
  final int viewCount;
  final List<String> viewedBy; // List of user UIDs who viewed

  AnnouncementModel({
    required this.id,
    required this.institutionId,
    required this.title,
    required this.description,
    this.content,
    required this.createdBy,
    required this.createdByName,
    required this.createdByRole,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledFor,
    this.isActive = true,
    this.targetAudience = const ['student', 'faculty', 'admin'],
    this.targetDepartments = const [],
    this.attachmentUrls = const [],
    this.priority = 2,
    this.category = 'general',
    this.isPinned = false,
    this.viewCount = 0,
    this.viewedBy = const [],
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String? ?? '',
      institutionId: json['institutionId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      content: json['content'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
      createdByName: json['creatorName'] as String? ?? json['createdByName'] as String? ?? '',
      createdByRole: json['createdByRole'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      scheduledFor: json['scheduledFor'] != null && json['scheduledFor'] != 0
          ? _parseDateTime(json['scheduledFor'])
          : null,
      isActive: json['isActive'] as bool? ?? true,
      targetAudience: List<String>.from(json['targetAudience'] as List? ?? ['student', 'faculty', 'admin']),
      targetDepartments: List<String>.from(json['targetDepartments'] as List? ?? []),
      attachmentUrls: List<String>.from(json['attachmentUrls'] as List? ?? []),
      priority: _convertPriorityStringToInt(json['priority'] as String? ?? 'MEDIUM'),
      category: _convertBackendCategoryToFrontend(json['category'] as String? ?? 'OTHER'),
      isPinned: json['isPinned'] as bool? ?? false,
      viewCount: json['viewCount'] as int? ?? 0,
      viewedBy: json['viewers'] is List
          ? (json['viewers'] as List).map((e) => (e as Map)['uid']?.toString() ?? '').toList()
          : List<String>.from(json['viewedBy'] as List? ?? []),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  static int _convertPriorityStringToInt(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return 3;
      case 'MEDIUM':
        return 2;
      case 'LOW':
        return 1;
      default:
        return 2;
    }
  }

  static String _convertBackendCategoryToFrontend(String category) {
    const categoryMap = {
      'OTHER': 'general',
      'ACADEMIC': 'academic',
      'EVENT': 'event',
      'ADMINISTRATIVE': 'urgent',
      'PLACEMENT': 'placement',
    };
    return categoryMap[category] ?? 'general';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institutionId': institutionId,
      'title': title,
      'description': description,
      'content': content,
      'createdBy': createdBy,
      'creatorName': createdByName,
      // Don't send creatorPhotoUrl - backend will set it
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'scheduledFor': scheduledFor?.millisecondsSinceEpoch ?? 0,
      'targetAudience': targetAudience.map((role) {
        String r = role.toUpperCase();
        if (r == 'STUDENT') return 'STUDENTS';
        return r;
      }).toList(),
      'targetDepartments': targetDepartments,
      'attachmentUrls': attachmentUrls,
      'priority': _convertPriorityToString(priority!),  // Convert int to string
      'category': _convertCategoryToBackendFormat(category!),  // Map category names
      'status': 'PUBLISHED',  // Default status
      'viewCount': 0,  // Server will initialize
      // Don't send viewers - server initializes as empty
    };
  }

  String _convertPriorityToString(int priority) {
    switch (priority) {
      case 3:
        return 'HIGH';
      case 2:
        return 'MEDIUM';
      case 1:
        return 'LOW';
      default:
        return 'MEDIUM';
    }
  }

  String _convertCategoryToBackendFormat(String category) {
    const categoryMap = {
      'general': 'OTHER',
      'academic': 'ACADEMIC',
      'event': 'EVENT',
      'urgent': 'ADMINISTRATIVE',
      'placement': 'PLACEMENT',
    };
    return categoryMap[category] ?? 'OTHER';
  }

  AnnouncementModel copyWith({
    String? id,
    String? institutionId,
    String? title,
    String? description,
    String? content,
    String? createdBy,
    String? createdByName,
    String? createdByRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledFor,
    bool? isActive,
    List<String>? targetAudience,
    List<String>? targetDepartments,
    List<String>? attachmentUrls,
    int? priority,
    String? category,
    int? viewCount,
    List<String>? viewedBy,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      institutionId: institutionId ?? this.institutionId,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByRole: createdByRole ?? this.createdByRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isActive: isActive ?? this.isActive,
      targetAudience: targetAudience ?? this.targetAudience,
      targetDepartments: targetDepartments ?? this.targetDepartments,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      viewCount: viewCount ?? this.viewCount,
      viewedBy: viewedBy ?? this.viewedBy,
    );
  }
}
