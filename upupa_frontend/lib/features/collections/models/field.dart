// upupa_frontend/lib/features/collections/models/field.dart
import 'package:json_annotation/json_annotation.dart';

part 'field.g.dart';

@JsonSerializable()
class Field {
  final String name;
  final String type;

  @JsonKey(defaultValue: false)
  final bool required;

  final dynamic defaultValue;

  @JsonKey(name: 'collectionId', includeIfNull: false)
  final String? collectionId;

  @JsonKey(name: 'options', includeIfNull: false)
  final Map<String, dynamic>? options;

  Field({
    required this.name,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.collectionId,
    this.options,
  });

  factory Field.fromJson(Map<String, dynamic> json) => _$FieldFromJson(json);

  Map<String, dynamic> toJson() => _$FieldToJson(this);
}
