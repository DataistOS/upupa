// upupa_frontend/lib/features/collections/widgets/fields/number_field_widget.dart
import 'package:flutter/material.dart';
import 'base_field_widget.dart';

class NumberFieldWidget extends StatelessWidget {
  final String name;
  final bool required;
  final TextEditingController controller;
  final FieldValidator validator;

  const NumberFieldWidget({
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: '$name (Number)',
          suffixText: required ? '*' : '',
          border: const OutlineInputBorder(),
        ),
        validator: (value) => validator(value, 'number', required),
      ),
    );
  }
}
