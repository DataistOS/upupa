// upupa_frontend/lib/features/collections/models/collection.dart
import 'field.dart';
import 'rule.dart';

class Collection {
  final String id;
  final String name;
  final bool system;
  final DateTime created;
  final DateTime updated;
  final List<Field> schema;
  final List<Rule> rules;
  int recordCount;

  Collection({
    required this.id,
    required this.name,
    required this.system,
    required this.created,
    required this.updated,
    required this.schema,
    required this.rules,
    this.recordCount = 0,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    final List<dynamic> schemaJson = json['schema'] ?? [];
    final List<Field> schemaList = schemaJson
        .map((f) => Field.fromJson(f))
        .toList();

    final List<dynamic> rulesJson = json['rules'] ?? [];
    final List<Rule> rulesList = rulesJson
        .map((r) => Rule.fromJson(r))
        .toList();

    return Collection(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      system: json['system'] ?? false,
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
      schema: schemaList,
      rules: rulesList,
      recordCount: json['recordCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'system': system,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'schema': schema.map((f) => f.toJson()).toList(),
      'rules': rules.map((r) => r.toJson()).toList(),
      'recordCount': recordCount,
    };
  }
}
