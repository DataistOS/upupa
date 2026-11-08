// upupa_frontend/lib/features/collections/widgets/fields/json_field_widget.dart
import 'package:flutter/material.dart';
import 'base_field_widget.dart';

class JsonFieldWidget extends StatelessWidget {
  final String name;
  final bool required;
  final TextEditingController controller;
  final FieldValidator validator;

  const JsonFieldWidget({
    super.key,
    required this.name,
    required this.required,
    required this.controller,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return BaseFieldLayout(
      label: name,
      required: required,
      child: TextFormField(
        controller: controller,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: '$name (JSON Content)',
          hintText: '{\n  "key": "value"\n}',
          suffixText: required ? '*' : '',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.code),
        ),
        validator: (value) => validator(value, 'json', required),
      ),
    );
  }
}
