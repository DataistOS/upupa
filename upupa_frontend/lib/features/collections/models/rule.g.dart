// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Rule _$RuleFromJson(Map<String, dynamic> json) => Rule(
  name: json['name'] as String,
  type: json['type'] as String,
  condition: json['condition'] as String,
  action: json['action'] as String,
  enabled: json['enabled'] as bool,
);

Map<String, dynamic> _$RuleToJson(Rule instance) => <String, dynamic>{
  'name': instance.name,
  'type': instance.type,
  'condition': instance.condition,
  'action': instance.action,
  'enabled': instance.enabled,
};
