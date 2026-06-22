// upupa_frontend/lib/features/collections/widgets/record_field_widget.dart
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/field.dart';

typedef FieldValueChangeCallback = void Function(dynamic value);

class RecordFieldWidget extends StatelessWidget {
  final Field field;
  final dynamic initialValue;
  final FieldValueChangeCallback onValueChanged;

  const RecordFieldWidget({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onValueChanged,
  });

  String get _label => field.name[0].toUpperCase() + field.name.substring(1);

  String? _validator(dynamic value) {
    if (field.required &&
        (value == null || (value is String && value.isEmpty))) {
      return '$_label is required.';
    }
    return null;
  }

  Widget _buildInputWidget(BuildContext context) {
    final String hintText = field.name;

    final String initialStringValue = initialValue?.toString() ?? '';

    switch (field.type) {
      case 'string':
        // ======================= STRING =======================
        return TextFormField(
          initialValue: initialStringValue,
          decoration: InputDecoration(
            labelText: _label,
            border: const OutlineInputBorder(),
            hintText: hintText,
          ),
          onChanged: onValueChanged,
          validator: (value) => _validator(value),
        );

      case 'number':
        // ======================= NUMBER =======================
        return TextFormField(
          initialValue: initialStringValue,
          decoration: InputDecoration(
            labelText: _label,
            border: const OutlineInputBorder(),
            hintText: hintText,
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final numValue = num.tryParse(value);
            onValueChanged(numValue);
          },
          validator: (value) {
            final error = _validator(value);
            if (error != null) return error;
            if (value != null &&
                value.isNotEmpty &&
                num.tryParse(value) == null) {
              return 'Must be a valid number.';
            }
            return null;
          },
        );

      case 'boolean':
        // ======================= BOOLEAN =======================
        bool isChecked = false;
        if (initialValue is bool) {
          isChecked = initialValue;
        } else if (initialValue is String) {
          isChecked =
              initialValue.toLowerCase() == 'true' || initialValue == '1';
        } else if (initialValue is num) {
          isChecked = initialValue != 0;
        }

        return CheckboxListTile(
          title: Text(_label),
          value: isChecked,
          onChanged: (bool? newValue) {
            onValueChanged(newValue ?? false);
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );

      case 'date':
        // ======================= DATE =======================

        String dateText = initialValue != null
            ? initialValue is DateTime
                  ? initialValue.toString().split(' ').first
                  : initialValue.toString()
            : 'Select Date';

        DateTime? initialDateTime;
        if (initialValue is DateTime) {
          initialDateTime = initialValue;
        } else if (initialValue is String) {
          try {
            initialDateTime = DateTime.tryParse(initialValue);
          } catch (_) {
            initialDateTime = null;
          }
        }

        return InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: initialDateTime ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null) {
              onValueChanged(picked);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: _label,
              border: const OutlineInputBorder(),
              hintText: hintText,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(
              dateText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );

      case 'file':
        // ======================= FILE =======================
        return _FilePickerInput(
          label: _label,
          initialValue: initialStringValue,
          onValueChanged: onValueChanged,
          validator: _validator,
        );

      default:
        return Text(
          'Unsupported field type: ${field.type}',
          style: const TextStyle(color: Colors.red),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBoolean = field.type == 'boolean';

    return Padding(
      padding: EdgeInsets.only(bottom: isBoolean ? 8.0 : 16.0),
      child: _buildInputWidget(context),
    );
  }
}

// ======================= FILE PICKER COMPONENT =======================

class _FilePickerInput extends StatefulWidget {
  final String label;
  final String initialValue;
  final FieldValueChangeCallback onValueChanged;
  final FormFieldValidator<String> validator;

  const _FilePickerInput({
    required this.label,
    required this.initialValue,
    required this.onValueChanged,
    required this.validator,
  });

  @override
  State<_FilePickerInput> createState() => __FilePickerInputState();
}

class __FilePickerInputState extends State<_FilePickerInput> {
  String? _selectedFilePath;
  late String _displayValue;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.initialValue;
    if (_displayValue.isNotEmpty) {
      _selectedFilePath = null;
    }
  }

  String get _currentDisplayValue {
    if (_selectedFilePath != null) {
      return _selectedFilePath!.split('/').last;
    }
    return _displayValue.isEmpty ? 'No file selected.' : _displayValue;
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final String filePath = result.files.single.path!;

      setState(() {
        _selectedFilePath = filePath;
      });

      widget.onValueChanged(filePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickFile,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          hintText: 'Tap to select file',
          suffixIcon: const Icon(Icons.attach_file),
        ),
        child: FormField<String>(
          initialValue: _selectedFilePath ?? _displayValue,
          validator: (value) => widget.validator(value),
          builder: (FormFieldState<String> state) {
            if (state.value != null && state.value!.isNotEmpty) {
              state.didChange(state.value);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentDisplayValue,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
