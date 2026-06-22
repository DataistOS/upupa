// upupa_frontend/lib/features/collections/models/rule.dart
import 'package:json_annotation/json_annotation.dart';

part 'rule.g.dart';

@JsonSerializable()
class Rule {
  final String name;
  final String type;
  final String condition;
  final String action;
  final bool enabled;

  Rule({
    required this.name,
    required this.type,
    required this.condition,
    required this.action,
    required this.enabled,
  });

  factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);

  Map<String, dynamic> toJson() => _$RuleToJson(this);

  Rule copyWith({
    String? name,
    String? type,
    String? condition,
    String? action,
    bool? enabled,
  }) {
    return Rule(
      name: name ?? this.name,
      type: type ?? this.type,
      condition: condition ?? this.condition,
      action: action ?? this.action,
      enabled: enabled ?? this.enabled,
    );
  }
}
