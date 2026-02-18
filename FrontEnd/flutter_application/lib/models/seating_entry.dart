class SeatingEntry {
  final String studentId;
  final String roomId;
  final String seatNumber;

  SeatingEntry({
    required this.studentId,
    required this.roomId,
    required this.seatNumber,
  });

  factory SeatingEntry.fromJson(Map<String, dynamic> json) {
    return SeatingEntry(
      studentId: json['studentId'],
      roomId: json['roomId'],
      seatNumber: json['seatNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'roomId': roomId,
      'seatNumber': seatNumber,
    };
  }
}
