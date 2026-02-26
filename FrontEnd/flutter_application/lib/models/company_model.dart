class CompanyModel {
  final String id;
  final String name;
  final String industry;
  final String website;
  final String hrEmail;
  final String description;
  final String tier;

  CompanyModel({
    required this.id,
    required this.name,
    required this.industry,
    required this.website,
    required this.hrEmail,
    required this.description,
    required this.tier,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      industry: json['industry'] ?? '',
      website: json['website'] ?? '',
      hrEmail: json['hrEmail'] ?? '',
      description: json['description'] ?? '',
      tier: json['tier'] ?? 'Tier 3',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'industry': industry,
      'website': website,
      'hrEmail': hrEmail,
      'description': description,
      'tier': tier,
    };
  }
}
