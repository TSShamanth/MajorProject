class FeeComponent {
  final String name;
  final double amount;

  FeeComponent({
    required this.name,
    required this.amount,
  });

  factory FeeComponent.fromJson(Map<String, dynamic> json) {
    return FeeComponent(
      name: json['name'] ?? '',
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }
}
