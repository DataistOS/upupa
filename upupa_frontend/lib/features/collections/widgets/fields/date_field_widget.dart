// upupa_frontend/lib/features/collections/widgets/fields/date_field_widget.dart
import 'package:flutter/material.dart';
import 'base_field_widget.dart';

class DateFieldWidget extends StatelessWidget {
  final String name;
  final String type; // date, autodate
  final bool required;
  final TextEditingController controller;
  final FieldValidator validator;

  const DateFieldWidget({
    super.key,
    required this.name,
    required this.type,
    required this.required,
    required this.controller,
    required this.validator,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      controller.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseFieldLayout(
      label: name,
      required: required,
      child: TextFormField(
        controller: controller,
        readOnly: type == 'autodate',
        decoration: InputDecoration(
          labelText:
              '$name (${type == 'autodate' ? 'Auto Date' : 'YYYY-MM-DD'})',
          suffixText: required ? '*' : '',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: type == 'date'
              ? IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: () => _selectDate(context),
                )
              : null,
        ),
        validator: (value) => validator(value, 'date', required),
      ),
    );
  }
}
