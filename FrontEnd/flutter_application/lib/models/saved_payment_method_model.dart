class SavedPaymentMethod {
  final String id;
  final String userId;
  final String methodType; // "CARD", "UPI"
  final String displayName; // "**** 1234", "my-upi@bank"
  final Map<String, String> details;

  SavedPaymentMethod({
    required this.id,
    required this.userId,
    required this.methodType,
    required this.displayName,
    required this.details,
  });

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      methodType: json['methodType'] ?? '',
      displayName: json['displayName'] ?? '',
      details: Map<String, String>.from(json['details'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'methodType': methodType,
      'displayName': displayName,
      'details': details,
    };
  }
}
