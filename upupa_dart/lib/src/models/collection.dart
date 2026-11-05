// upupa_dart/lib/src/models/collection.dart
class Collection {
  final String id;
  final String name;
  final String type;
  final DateTime? created;
  final DateTime? updated;

  Collection({
    required this.id,
    required this.name,
    required this.type,
    this.created,
    this.updated,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String),
      updated: json['updated'] == null
          ? null
          : DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }
}
