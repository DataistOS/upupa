// upupa_frontend/lib/features/collections/widgets/fields/select_field_widget.dart
import 'package:flutter/material.dart';
import 'base_field_widget.dart';

class SelectFieldWidget extends StatelessWidget {
  final String name;
  final bool required;
  final String? value;
  final Map<String, dynamic> options;
  final ValueChanged<String?> onChanged;

  const SelectFieldWidget({
    super.key,
    required this.name,
    required this.required,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> valuesList = [];
    if (options['values'] is List) {
      valuesList = options['values'];
    }

    return BaseFieldLayout(
      label: name,
      required: required,
      child: DropdownButtonFormField<String>(
        value: valuesList.contains(value) ? value : null,
        decoration: InputDecoration(
          labelText: '$name (Select)',
          suffixText: required ? '*' : '',
          border: const OutlineInputBorder(),
        ),
        items: valuesList.map<DropdownMenuItem<String>>((val) {
          return DropdownMenuItem<String>(
            value: val.toString(),
            child: Text(val.toString()),
          );
        }).toList(),
        hint: const Text('Select option'),
        onChanged: onChanged,
        validator: (val) {
          if (required && (val == null || val.isEmpty)) {
            return 'This select field is required.';
          }
          return null;
        },
      ),
    );
  }
}
