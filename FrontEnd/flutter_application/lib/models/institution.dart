class Institution {
  final String id;
  final String name;

  Institution({required this.id, required this.name});

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'],
      name: json['name'],
    );
  }
}
