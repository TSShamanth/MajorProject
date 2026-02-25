import 'fee_component_model.dart';

class FeeStructure {
  final String id;
  final String title;
  final String institutionId;
  final String departmentId;
  final String semester;
  final List<FeeComponent> components;
  final double totalAmount;

  FeeStructure({
    required this.id,
    required this.title,
    required this.institutionId,
    required this.departmentId,
    required this.semester,
    required this.components,
    required this.totalAmount,
  });

  factory FeeStructure.fromJson(Map<String, dynamic> json) {
    return FeeStructure(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      institutionId: json['institutionId'] ?? '',
      departmentId: json['departmentId'] ?? '',
      semester: json['semester'] ?? '',
      components: (json['components'] as List?)
              ?.map((c) => FeeComponent.fromJson(c))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'institutionId': institutionId,
      'departmentId': departmentId,
      'semester': semester,
      'components': components.map((c) => c.toJson()).toList(),
      'totalAmount': totalAmount,
    };
  }
}
