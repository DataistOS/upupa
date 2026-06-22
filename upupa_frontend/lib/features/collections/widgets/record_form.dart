// upupa_frontend/lib/features/collections/widgets/record_form.dart
import 'package:flutter/material.dart';

import '../models/collection.dart';
import '../models/record.dart';

class RecordForm extends StatefulWidget {
  final Collection collection;
  final Record? record;

  const RecordForm({
    super.key,
    required this.collection,
    this.record,
  });

  @override
  State<RecordForm> createState() => RecordFormState();
}

class RecordFormState extends State<RecordForm> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _checkboxValues = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var field in widget.collection.schema) {
      final key = field.name;

      dynamic initialValue;
      if (widget.record != null && widget.record!.data.containsKey(key)) {
        initialValue = widget.record!.data[key];
      } else {
        initialValue = field.defaultValue;
      }

      if (field.type == 'boolean') {
        _checkboxValues[key] = initialValue as bool? ?? false;
      } else {
        _controllers[key] = TextEditingController(
          text: initialValue?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Map<String, dynamic> getFormData() {
    final Map<String, dynamic> data = {};
    for (var field in widget.collection.schema) {
      final fieldName = field.name;

      if (field.type == 'boolean') {
        data[fieldName] = _checkboxValues[fieldName] ?? false;
      } else {
        final controller = _controllers[fieldName]!;
        if (field.type == 'number') {
          data[fieldName] =
              double.tryParse(controller.text) ?? (field.required ? 0.0 : null);
        } else {
          data[fieldName] = controller.text;
        }
      }
    }

    return data;
  }

  String? _validator(String? value, String type, bool required) {
    if (required && (value == null || value.isEmpty)) {
      return 'This field is required.';
    }
    if (value != null && value.isNotEmpty) {
      if (type == 'number') {
        if (double.tryParse(value) == null) {
          return 'Must be a valid number.';
        }
      }
    }
    return null;
  }

  Widget _buildFieldInput(String fieldName, String type, bool required) {
    switch (type) {
      case 'boolean':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Checkbox(
                value: _checkboxValues[fieldName],
                onChanged: (bool? newValue) {
                  if (!mounted) return;
                  setState(() {
                    _checkboxValues[fieldName] = newValue ?? false;
                  });
                },
              ),
              Text(fieldName),
            ],
          ),
        );
      case 'number':
        return TextFormField(
          controller: _controllers[fieldName],
          decoration: InputDecoration(
            labelText: fieldName,
            suffixText: required ? '*' : '',
          ),
          keyboardType: TextInputType.number,
          validator: (value) => _validator(value, 'number', required),
        );
      case 'string':
      default:
        return TextFormField(
          controller: _controllers[fieldName],
          decoration: InputDecoration(
            labelText: fieldName,
            suffixText: required ? '*' : '',
          ),
          validator: (value) => _validator(value, 'string', required),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: widget.collection.schema
            .where((field) => field.name != 'password_hash')
            .map((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildFieldInput(
              field.name,
              field.type,
              field.required,
            ),
          );
        }).toList(),
      ),
    );
  }
}