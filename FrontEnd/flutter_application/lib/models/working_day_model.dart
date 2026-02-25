class WorkingDay {
  final String? id;
  final String dayName;
  final bool isWorking;
  final String institutionId;

  WorkingDay({
    this.id,
    required this.dayName,
    required this.isWorking,
    required this.institutionId,
  });

  factory WorkingDay.fromJson(Map<String, dynamic> json) {
    return WorkingDay(
      id: json['id'],
      dayName: json['dayName'],
      isWorking: json['working'] ?? false, // Check name in backend (isWorking vs working)
      institutionId: json['institutionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayName': dayName,
      'working': isWorking,
      'institutionId': institutionId,
    };
  }
}
