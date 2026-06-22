// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Field _$FieldFromJson(Map<String, dynamic> json) => Field(
  name: json['name'] as String,
  type: json['type'] as String,
  required: json['required'] as bool? ?? false,
  defaultValue: json['defaultValue'],
);

Map<String, dynamic> _$FieldToJson(Field instance) => <String, dynamic>{
  'name': instance.name,
  'type': instance.type,
  'required': instance.required,
  'defaultValue': instance.defaultValue,
};
