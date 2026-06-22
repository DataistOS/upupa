// upupa_frontend/lib/features/collections/models/record.dart
import 'package:json_annotation/json_annotation.dart';

part 'record.g.dart';

@JsonSerializable()
class Record {
  final String id;

  @JsonKey(name: 'collectionId')
  final String collectionID;

  final DateTime created;
  final DateTime updated;

  final Map<String, dynamic> data;

  Record({
    required this.id,
    required this.collectionID,
    required this.created,
    required this.updated,
    required this.data,
  });

  factory Record.fromJson(Map<String, dynamic> json) => _$RecordFromJson(json);

  Map<String, dynamic> toJson() => _$RecordToJson(this);
}
