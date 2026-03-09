class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String? route;
  final DateTime createdAt;
  final bool read;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.route,
    required this.createdAt,
    required this.read,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      route: json['route'] as String?,
      createdAt: json['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : json['createdAt'] is String
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      read: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      if (route != null) 'route': route,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'read': read,
    };
  }
}
