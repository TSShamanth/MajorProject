class TimeSlot {
  final String? id;
  final int slotNumber;
  final String startTime;
  final String endTime;
  final String institutionId;

  TimeSlot({
    this.id,
    required this.slotNumber,
    required this.startTime,
    required this.endTime,
    required this.institutionId,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'],
      slotNumber: json['slotNumber'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      institutionId: json['institutionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slotNumber': slotNumber,
      'startTime': startTime,
      'endTime': endTime,
      'institutionId': institutionId,
    };
  }
}
