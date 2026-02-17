class Department {
  final String id;
  final String name;
  final String shortName;
  final String institutionId;

  Department({
    required this.id,
    required this.name,
    required this.shortName,
    required this.institutionId,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
      shortName: json['shortName'],
      institutionId: json['institutionId'],
    );
  }
}
