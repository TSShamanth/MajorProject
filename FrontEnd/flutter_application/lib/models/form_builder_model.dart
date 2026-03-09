class CustomForm {
  final String id;
  final String institutionId;
  final String title;
  final String description;
  final String createdBy;
  final int createdAt;
  final int updatedAt;
  final int expiryDate;
  final bool isOpen;
  final bool allowMultipleSubmissions;
  final List<String> targetAudience;
  final List<FormFieldModel> fields;

  CustomForm({
    required this.id,
    required this.institutionId,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.expiryDate,
    required this.isOpen,
    this.allowMultipleSubmissions = false,
    required this.targetAudience,
    required this.fields,
  });

  factory CustomForm.fromJson(Map<String, dynamic> json) {
    return CustomForm(
      id: json['id'] ?? '',
      institutionId: json['institutionId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] ?? 0,
      updatedAt: json['updatedAt'] ?? 0,
      expiryDate: json['expiryDate'] ?? 0,
      isOpen: json['isOpen'] ?? true,
      allowMultipleSubmissions: json['allowMultipleSubmissions'] ?? false,
      targetAudience: List<String>.from(json['targetAudience'] ?? []),
      fields: (json['fields'] as List? ?? [])
          .map((f) => FormFieldModel.fromJson(f))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institutionId': institutionId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'expiryDate': expiryDate,
      'isOpen': isOpen,
      'allowMultipleSubmissions': allowMultipleSubmissions,
      'targetAudience': targetAudience,
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }
}

class FormFieldModel {
  final String id;
  final String type;
  final String label;
  final String placeholder;
  final bool isRequired;
  final List<String> options;
  final int? minScale;
  final int? maxScale;

  FormFieldModel({
    required this.id,
    required this.type,
    required this.label,
    required this.placeholder,
    required this.isRequired,
    this.options = const [],
    this.minScale,
    this.maxScale,
  });

  factory FormFieldModel.fromJson(Map<String, dynamic> json) {
    return FormFieldModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'TEXT',
      label: json['label'] ?? '',
      placeholder: json['placeholder'] ?? '',
      isRequired: json['isRequired'] ?? false,
      options: List<String>.from(json['options'] ?? []),
      minScale: json['minScale'],
      maxScale: json['maxScale'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'label': label,
      'placeholder': placeholder,
      'isRequired': isRequired,
      'options': options,
      'minScale': minScale,
      'maxScale': maxScale,
    };
  }
}

class FormResponseModel {
  final String id;
  final String formId;
  final String userId;
  final String institutionId;
  final int submittedAt;
  final Map<String, dynamic> answers;

  FormResponseModel({
    required this.id,
    required this.formId,
    required this.userId,
    required this.institutionId,
    required this.submittedAt,
    required this.answers,
  });

  factory FormResponseModel.fromJson(Map<String, dynamic> json) {
    return FormResponseModel(
      id: json['id'] ?? '',
      formId: json['formId'] ?? '',
      userId: json['userId'] ?? '',
      institutionId: json['institutionId'] ?? '',
      submittedAt: json['submittedAt'] ?? 0,
      answers: Map<String, dynamic>.from(json['answers'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'formId': formId,
      'userId': userId,
      'institutionId': institutionId,
      'submittedAt': submittedAt,
      'answers': answers,
    };
  }
}
