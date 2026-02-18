class ProfessorDto {
  final String uid;
  final String displayName;

  ProfessorDto({
    required this.uid,
    required this.displayName,
  });

  factory ProfessorDto.fromJson(Map<String, dynamic> json) {
    return ProfessorDto(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
    };
  }

  @override
  String toString() => displayName;
}
