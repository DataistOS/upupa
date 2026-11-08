// upupa_frontend/lib/features/collections/widgets/fields/text_field_widget.dart
import 'package:flutter/material.dart';
import 'base_field_widget.dart';

class TextFieldWidget extends StatelessWidget {
  final String name;
  final String type; // text, string, email, url, editor
  final bool required;
  final TextEditingController controller;
  final FieldValidator validator;

  const TextFieldWidget({
    super.key,
    required this.name,
    required this.type,
    required this.required,
    required this.controller,
    required this.validator,
  });

  TextInputType _getKeyboardType() {
    switch (type) {
      case 'email':
        return TextInputType.emailAddress;
      case 'url':
        return TextInputType.url;
      case 'editor':
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditor = type == 'editor';

    return BaseFieldLayout(
      label: name,
      required: required,
      child: TextFormField(
        controller: controller,
        maxLines: isEditor ? 5 : 1,
        keyboardType: _getKeyboardType(),
        decoration: InputDecoration(
          labelText: '$name (${type.toUpperCase()})',
          suffixText: required ? '*' : '',
          border: const OutlineInputBorder(),
        ),
        validator: (value) => validator(value, type, required),
      ),
    );
  }
}
