class Field {
  final String name;
  final String type;
  final bool required;
  final dynamic defaultValue;
  final Map<String, dynamic>? options;
  final String? collectionId;

  Field({
    required this.name,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.options,
    this.collectionId,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      name: json['name'] ?? '',
      type: json['type'] ?? 'text',
      required: json['required'] ?? false,
      defaultValue: json['defaultValue'],
      options: json['options'] != null
          ? Map<String, dynamic>.from(json['options'])
          : null,
      collectionId: json['collectionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'required': required,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (options != null) 'options': options,
      if (collectionId != null) 'collectionId': collectionId,
    };
  }
}
