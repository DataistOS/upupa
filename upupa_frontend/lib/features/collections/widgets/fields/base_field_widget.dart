// upupa_frontend/lib/features/collections/widgets/fields/base_field_widget.dart
import 'package:flutter/material.dart';

typedef FieldValidator =
    String? Function(String? value, String type, bool required);

class BaseFieldLayout extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const BaseFieldLayout({
    super.key,
    required this.label,
    required this.required,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 16.0), child: child);
  }
}
