class Room {
  final String id;
  final String name;
  final int capacity;
  final String institutionId;
  final String? departmentId;

  Room({
    required this.id,
    required this.name,
    required this.capacity,
    required this.institutionId,
    this.departmentId,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      capacity: json['capacity'],
      institutionId: json['institutionId'],
      departmentId: json['departmentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'institutionId': institutionId,
      'departmentId': departmentId,
    };
  }
}
