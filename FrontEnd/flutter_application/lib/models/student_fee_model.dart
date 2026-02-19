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
  final String status; // UNPAID, PARTIAL, PAID
  final DateTime? dueDate;
  final DateTime? createdAt;

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
    required this.status,
    this.dueDate,
    this.createdAt,
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
      status: json['status'] ?? 'UNPAID',
      dueDate: json['dueDate'] != null && json['dueDate'] is String ? DateTime.parse(json['dueDate']) : null,
      createdAt: json['createdAt'] != null && json['createdAt'] is String ? DateTime.parse(json['createdAt']) : null,
    );
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
      'status': status,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
