// upupa_frontend/lib/features/collections/widgets/fields/geopoint_field_widget.dart
import 'package:flutter/material.dart';
import 'base_field_widget.dart';

class GeoPointFieldWidget extends StatelessWidget {
  final String name;
  final bool required;
  final TextEditingController controller;
  final FieldValidator validator;

  const GeoPointFieldWidget({
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
        decoration: InputDecoration(
          labelText: '$name (Lat, Lng)',
          hintText: 'e.g. 35.6892, 51.3890',
          suffixText: required ? '*' : '',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.location_on),
        ),
        validator: (value) => validator(value, 'geopoint', required),
      ),
    );
  }
}
