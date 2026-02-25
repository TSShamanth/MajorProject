class Payment {
  final String id;
  final String studentFeeId;
  final String studentId;
  final String institutionId;
  final double amountPaid;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? transactionId;
  final String receiptNumber;
  final String? notes;

  Payment({
    required this.id,
    required this.studentFeeId,
    required this.studentId,
    required this.institutionId,
    required this.amountPaid,
    required this.paymentDate,
    required this.paymentMethod,
    this.transactionId,
    required this.receiptNumber,
    this.notes,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      studentFeeId: json['studentFeeId'] ?? '',
      studentId: json['studentId'] ?? '',
      institutionId: json['institutionId'] ?? '',
      amountPaid: (json['amountPaid'] as num? ?? 0.0).toDouble(),
      paymentDate: json['paymentDate'] != null && json['paymentDate'] is String
          ? DateTime.parse(json['paymentDate'])
          : DateTime.now(), // Fallback to now if not string or null
      paymentMethod: json['paymentMethod'] ?? '',
      transactionId: json['transactionId'],
      receiptNumber: json['receiptNumber'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentFeeId': studentFeeId,
      'studentId': studentId,
      'institutionId': institutionId,
      'amountPaid': amountPaid,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'receiptNumber': receiptNumber,
      'notes': notes,
    };
  }
}
