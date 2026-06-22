// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Record _$RecordFromJson(Map<String, dynamic> json) => Record(
  id: json['id'] as String,
  collectionID: json['collectionId'] as String,
  created: DateTime.parse(json['created'] as String),
  updated: DateTime.parse(json['updated'] as String),
  data: json['data'] as Map<String, dynamic>,
);

Map<String, dynamic> _$RecordToJson(Record instance) => <String, dynamic>{
  'id': instance.id,
  'collectionId': instance.collectionID,
  'created': instance.created.toIso8601String(),
  'updated': instance.updated.toIso8601String(),
  'data': instance.data,
};
