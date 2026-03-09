class Institution {
  final String id;
  final String name;
  final String? address;
  final String? email;
  final String? phone;
  final String? primaryColor;
  final String? logoUrl;

  Institution({
    required this.id,
    required this.name,
    this.address,
    this.email,
    this.phone,
    this.primaryColor,
    this.logoUrl,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      email: json['email'],
      phone: json['phone'],
      primaryColor: json['primaryColor'],
      logoUrl: json['logoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'email': email,
      'phone': phone,
      'primaryColor': primaryColor,
      'logoUrl': logoUrl,
    };
  }
}
