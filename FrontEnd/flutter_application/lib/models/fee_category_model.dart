class FeeCategory {
  final String id;
  final String name;
  final String institutionId;

  FeeCategory({
    required this.id,
    required this.name,
    required this.institutionId,
  });

  factory FeeCategory.fromJson(Map<String, dynamic> json) {
    return FeeCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      institutionId: json['institutionId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'institutionId': institutionId,
    };
  }
}
