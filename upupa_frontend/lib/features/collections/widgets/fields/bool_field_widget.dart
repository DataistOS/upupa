// upupa_frontend/lib/features/collections/widgets/fields/bool_field_widget.dart
import 'package:flutter/material.dart';
import 'base_field_widget.dart';

class BoolFieldWidget extends StatelessWidget {
  final String name;
  final bool required;
  final bool value;
  final ValueChanged<bool> onChanged;

  const BoolFieldWidget({
    super.key,
    required this.name,
    required this.required,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BaseFieldLayout(
      label: name,
      required: required,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: (bool? newValue) {
                  if (newValue != null) onChanged(newValue);
                },
              ),
              Text(
                name + (required ? ' *' : ''),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
