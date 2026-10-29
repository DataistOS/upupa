// upupa_frontend/lib/features/collections/widgets/record_field_widget.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/field.dart';
import '../models/record.dart';
import '../services/collection_service.dart';

typedef FieldValueChangeCallback = void Function(dynamic value);

class RecordFieldWidget extends StatefulWidget {
  final Field field;
  final dynamic initialValue;
  final FieldValueChangeCallback onValueChanged;

  const RecordFieldWidget({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onValueChanged,
  });

  @override
  State<RecordFieldWidget> createState() => _RecordFieldWidgetState();
}

class _RecordFieldWidgetState extends State<RecordFieldWidget> {
  List<Record> _targetRecords = [];
  bool _isLoadingRelation = false;

  String get _label =>
      widget.field.name[0].toUpperCase() + widget.field.name.substring(1);

  @override
  void initState() {
    super.initState();
    if (widget.field.type == 'relation' && widget.field.collectionId != null) {
      _loadTargetRecords();
    }
  }

  Future<void> _loadTargetRecords() async {
    setState(() {
      _isLoadingRelation = true;
    });
    try {
      final records = await CollectionService.getRecordsForCollection(
        widget.field.collectionId!,
      );
      if (!mounted) return;
      setState(() {
        _targetRecords = records;
        _isLoadingRelation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRelation = false;
      });
    }
  }

  String? _validator(dynamic value) {
    if (widget.field.required &&
        (value == null || (value is String && value.isEmpty))) {
      return '$_label is required.';
    }
    return null;
  }

  Widget _buildInputWidget(BuildContext context) {
    final String hintText = widget.field.name;
    final String initialStringValue = widget.initialValue?.toString() ?? '';

    switch (widget.field.type) {
      case 'string':
        // ======================= STRING =======================
        return TextFormField(
          initialValue: initialStringValue,
          decoration: InputDecoration(
            labelText: _label,
            border: const OutlineInputBorder(),
            hintText: hintText,
          ),
          onChanged: widget.onValueChanged,
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
            widget.onValueChanged(numValue);
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
        if (widget.initialValue is bool) {
          isChecked = widget.initialValue;
        } else if (widget.initialValue is String) {
          isChecked =
              widget.initialValue.toLowerCase() == 'true' ||
              widget.initialValue == '1';
        } else if (widget.initialValue is num) {
          isChecked = widget.initialValue != 0;
        }

        return CheckboxListTile(
          title: Text(_label),
          value: isChecked,
          onChanged: (bool? newValue) {
            widget.onValueChanged(newValue ?? false);
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );

      case 'relation':
        // ======================= RELATION =======================
        String? selectedValue;
        if (widget.initialValue != null &&
            widget.initialValue.toString().isNotEmpty) {
          final stringVal = widget.initialValue.toString();
          if (_targetRecords.any((rec) => rec.id == stringVal)) {
            selectedValue = stringVal;
          }
        }

        return DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            labelText: _label,
            border: const OutlineInputBorder(),
            hintText: _isLoadingRelation
                ? 'Loading items...'
                : 'Select related record',
          ),
          items: _targetRecords.map<DropdownMenuItem<String>>((rec) {
            String displayLabel = rec.id;
            if (rec.data.isNotEmpty) {
              for (var val in rec.data.values) {
                if (val != null) {
                  displayLabel = val.toString();
                  break;
                }
              }
            }
            return DropdownMenuItem<String>(
              value: rec.id,
              child: Text(displayLabel),
            );
          }).toList(),
          onChanged: (String? newValue) {
            widget.onValueChanged(newValue);
          },
          validator: (value) => _validator(value),
        );

      case 'date':
        // ======================= DATE =======================
        String dateText = widget.initialValue != null
            ? widget.initialValue is DateTime
                  ? widget.initialValue.toString().split(' ').first
                  : widget.initialValue.toString()
            : 'Select Date';

        DateTime? initialDateTime;
        if (widget.initialValue is DateTime) {
          initialDateTime = widget.initialValue;
        } else if (widget.initialValue is String) {
          try {
            initialDateTime = DateTime.tryParse(widget.initialValue);
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
              widget.onValueChanged(picked);
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
          onValueChanged: widget.onValueChanged,
          validator: _validator,
        );

      default:
        return Text(
          'Unsupported field type: ${widget.field.type}',
          style: const TextStyle(color: Colors.red),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBoolean = widget.field.type == 'boolean';

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
    FilePickerResult? result = await FilePicker.pickFiles(withData: true);

    if (result != null && result.files.single.bytes != null) {
      final fileName = result.files.single.name;

      setState(() {
        _selectedFilePath = fileName;
      });

      widget.onValueChanged(fileName);
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
