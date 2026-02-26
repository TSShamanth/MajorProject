class PlacementDriveModel {
  final String id;
  final String companyId;
  final String companyName;
  final String jobRole;
  final double salaryPackage;
  final String salaryBreakdown; // e.g. "Base: 12L, Performance: 2L"
  final String date;
  final String status; // 'Draft', 'Active', 'Completed'
  final String eligibilityCriteria;
  final double minCgpa;
  final int maxBacklogs;
  final double min10thPercentage;
  final double min12thPercentage;
  final List<String> allowedDepartments;
  final List<String> recruitmentRounds;
  final Map<String, int> pipelineStats; // e.g. {"Applied": 150, "Technical": 40}

  PlacementDriveModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.jobRole,
    required this.salaryPackage,
    this.salaryBreakdown = '',
    required this.date,
    required this.status,
    required this.eligibilityCriteria,
    required this.minCgpa,
    this.maxBacklogs = 0,
    this.min10thPercentage = 0.0,
    this.min12thPercentage = 0.0,
    required this.allowedDepartments,
    required this.recruitmentRounds,
    this.pipelineStats = const {},
  });

  factory PlacementDriveModel.fromJson(Map<String, dynamic> json) {
    return PlacementDriveModel(
      id: json['id'] ?? '',
      companyId: json['companyId'] ?? '',
      companyName: json['companyName'] ?? '',
      jobRole: json['jobRole'] ?? '',
      salaryPackage: (json['salaryPackage'] as num?)?.toDouble() ?? 0.0,
      salaryBreakdown: json['salaryBreakdown'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'Draft',
      eligibilityCriteria: json['eligibilityCriteria'] ?? '',
      minCgpa: (json['minCgpa'] as num?)?.toDouble() ?? 0.0,
      maxBacklogs: json['maxBacklogs'] ?? 0,
      min10thPercentage: (json['min10thPercentage'] as num?)?.toDouble() ?? 0.0,
      min12thPercentage: (json['min12thPercentage'] as num?)?.toDouble() ?? 0.0,
      allowedDepartments: List<String>.from(json['allowedDepartments'] ?? []),
      recruitmentRounds: List<String>.from(json['recruitmentRounds'] ?? []),
      pipelineStats: Map<String, int>.from(json['pipelineStats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'jobRole': jobRole,
      'salaryPackage': salaryPackage,
      'salaryBreakdown': salaryBreakdown,
      'date': date,
      'status': status,
      'eligibilityCriteria': eligibilityCriteria,
      'minCgpa': minCgpa,
      'maxBacklogs': maxBacklogs,
      'min10thPercentage': min10thPercentage,
      'min12thPercentage': min12thPercentage,
      'allowedDepartments': allowedDepartments,
      'recruitmentRounds': recruitmentRounds,
      'pipelineStats': pipelineStats,
    };
  }
}
