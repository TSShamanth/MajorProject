import 'package:intl/intl.dart';

class EventModel {
  final String id;
  final String institutionId;
  final String title;
  final String description;
  final String category; // ACADEMIC, PLACEMENT, CULTURAL, ADMINISTRATIVE, WORKSHOP, etc.
  final String status; // DRAFT, PENDING_APPROVAL, APPROVED, PUBLISHED, CANCELLED, COMPLETED
  
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String venue;
  final String? onlineLink;
  
  final String organizerId;
  final String organizerName;
  final String? organizerPhotoUrl;
  
  final int capacityLimit; // 0 for unlimited
  final int currentParticipants;
  final DateTime registrationDeadline;
  
  final List<String> targetAudience;
  final List<String> targetDepartments;
  
  final String? posterUrl;
  final List<String> attachmentUrls;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  
  final bool isApprovalRequired;
  final String? approvedBy;
  final DateTime? approvedAt;

  EventModel({
    required this.id,
    required this.institutionId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.startDateTime,
    required this.endDateTime,
    required this.venue,
    this.onlineLink,
    required this.organizerId,
    required this.organizerName,
    this.organizerPhotoUrl,
    required this.capacityLimit,
    required this.currentParticipants,
    required this.registrationDeadline,
    required this.targetAudience,
    required this.targetDepartments,
    this.posterUrl,
    required this.attachmentUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isApprovalRequired = false,
    this.approvedBy,
    this.approvedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      institutionId: json['institutionId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'GENERAL',
      status: json['status'] ?? 'PUBLISHED',
      startDateTime: DateTime.fromMillisecondsSinceEpoch(json['startDateTime'] ?? 0),
      endDateTime: DateTime.fromMillisecondsSinceEpoch(json['endDateTime'] ?? 0),
      venue: json['venue'] ?? '',
      onlineLink: json['onlineLink'],
      organizerId: json['organizerId'] ?? '',
      organizerName: json['organizerName'] ?? '',
      organizerPhotoUrl: json['organizerPhotoUrl'],
      capacityLimit: json['capacityLimit'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      registrationDeadline: DateTime.fromMillisecondsSinceEpoch(json['registrationDeadline'] ?? 0),
      targetAudience: List<String>.from(json['targetAudience'] ?? []),
      targetDepartments: List<String>.from(json['targetDepartments'] ?? []),
      posterUrl: json['posterUrl'],
      attachmentUrls: List<String>.from(json['attachmentUrls'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
      createdBy: json['createdBy'] ?? '',
      isApprovalRequired: json['isApprovalRequired'] ?? false,
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['approvedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institutionId': institutionId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'startDateTime': startDateTime.millisecondsSinceEpoch,
      'endDateTime': endDateTime.millisecondsSinceEpoch,
      'venue': venue,
      'onlineLink': onlineLink,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerPhotoUrl': organizerPhotoUrl,
      'capacityLimit': capacityLimit,
      'currentParticipants': currentParticipants,
      'registrationDeadline': registrationDeadline.millisecondsSinceEpoch,
      'targetAudience': targetAudience,
      'targetDepartments': targetDepartments,
      'posterUrl': posterUrl,
      'attachmentUrls': attachmentUrls,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'isApprovalRequired': isApprovalRequired,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.millisecondsSinceEpoch,
    };
  }

  EventModel copyWith({
    String? id,
    String? institutionId,
    String? title,
    String? description,
    String? category,
    String? status,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? venue,
    String? onlineLink,
    String? organizerId,
    String? organizerName,
    String? organizerPhotoUrl,
    int? capacityLimit,
    int? currentParticipants,
    DateTime? registrationDeadline,
    List<String>? targetAudience,
    List<String>? targetDepartments,
    String? posterUrl,
    List<String>? attachmentUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isApprovalRequired,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      institutionId: institutionId ?? this.institutionId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      venue: venue ?? this.venue,
      onlineLink: onlineLink ?? this.onlineLink,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      organizerPhotoUrl: organizerPhotoUrl ?? this.organizerPhotoUrl,
      capacityLimit: capacityLimit ?? this.capacityLimit,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      targetAudience: targetAudience ?? this.targetAudience,
      targetDepartments: targetDepartments ?? this.targetDepartments,
      posterUrl: posterUrl ?? this.posterUrl,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isApprovalRequired: isApprovalRequired ?? this.isApprovalRequired,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(startDateTime);
  String get formattedTime => DateFormat('hh:mm a').format(startDateTime);
  bool get isFull => capacityLimit > 0 && currentParticipants >= capacityLimit;
  bool get isRegistrationClosed {
    if (registrationDeadline.millisecondsSinceEpoch <= 0) return false;
    return DateTime.now().isAfter(registrationDeadline);
  }
  bool get isEventOver {
    if (status.toUpperCase() == 'REJECTED') return true;
    if (endDateTime.millisecondsSinceEpoch <= 0) return false;
    return DateTime.now().isAfter(endDateTime);
  }
}

// TODO: Need to impliment registered studentents details storage for admin and organizer to view and manage registrations.