class Section {
  final String? id;
  final String name;
  final String departmentId;
  final String institutionId;
  final String? facultyId;
  final List<String> studentIds;

  Section({
    this.id,
    required this.name,
    required this.departmentId,
    required this.institutionId,
    this.facultyId,
    required this.studentIds,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'],
      name: json['name'],
      departmentId: json['departmentId'],
      institutionId: json['institutionId'],
      facultyId: json['facultyId'],
      studentIds: List<String>.from(json['studentIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'departmentId': departmentId,
      'institutionId': institutionId,
      'facultyId': facultyId,
      'studentIds': studentIds,
    };
  }
}
