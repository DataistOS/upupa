class Rule {
  final String action;
  final String? expression;

  Rule({required this.action, this.expression});

  factory Rule.fromJson(Map<String, dynamic> json) {
    return Rule(action: json['action'] ?? '', expression: json['expression']);
  }

  Map<String, dynamic> toJson() {
    return {'action': action, if (expression != null) 'expression': expression};
  }
}
