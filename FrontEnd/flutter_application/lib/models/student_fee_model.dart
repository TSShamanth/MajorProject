import 'fee_component_model.dart';

class StudentFee {
  final String id;
  final String studentId;
  final String studentName;
  final String usn;
  final String institutionId;
  final String feeStructureId;
  final String feeStructureTitle;
  final List<FeeComponent> components;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final double fineAmount;
  final String status; // UNPAID, PARTIAL, PAID
  final DateTime? dueDate;
  final DateTime? createdAt;
  final String? facultyRemarks;

  StudentFee({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.usn,
    required this.institutionId,
    required this.feeStructureId,
    required this.feeStructureTitle,
    required this.components,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.fineAmount,
    required this.status,
    this.dueDate,
    this.createdAt,
    this.facultyRemarks,
  });

  factory StudentFee.fromJson(Map<String, dynamic> json) {
    return StudentFee(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      usn: json['usn'] ?? '',
      institutionId: json['institutionId'] ?? '',
      feeStructureId: json['feeStructureId'] ?? '',
      feeStructureTitle: json['feeStructureTitle'] ?? '',
      components: (json['components'] as List?)
              ?.map((c) => FeeComponent.fromJson(c))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num? ?? 0.0).toDouble(),
      paidAmount: (json['paidAmount'] as num? ?? 0.0).toDouble(),
      balanceAmount: (json['balanceAmount'] as num? ?? 0.0).toDouble(),
      fineAmount: (json['fineAmount'] as num? ?? 0.0).toDouble(),
      status: json['status'] ?? 'UNPAID',
      dueDate: json['dueDate'] != null ? _parseDate(json['dueDate']) : null,
      createdAt: json['createdAt'] != null ? _parseDate(json['createdAt']) : null,
      facultyRemarks: json['facultyRemarks'],
    );
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is String) return DateTime.parse(date);
    if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'usn': usn,
      'institutionId': institutionId,
      'feeStructureId': feeStructureId,
      'feeStructureTitle': feeStructureTitle,
      'components': components.map((c) => c.toJson()).toList(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'fineAmount': fineAmount,
      'status': status,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'facultyRemarks': facultyRemarks,
    };
  }
}
