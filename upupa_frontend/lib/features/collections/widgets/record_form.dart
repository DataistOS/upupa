// upupa_frontend/lib/features/collections/widgets/record_form.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/collection.dart';
import '../models/record.dart';
import '../services/collection_service.dart';

class RecordForm extends StatefulWidget {
  final Collection collection;
  final Record? record;

  const RecordForm({super.key, required this.collection, this.record});

  @override
  State<RecordForm> createState() => RecordFormState();
}

class RecordFormState extends State<RecordForm> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _checkboxValues = {};
  final Map<String, String> _fileValues = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isUploading = false;

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
      } else if (field.type == 'file') {
        _fileValues[key] = initialValue?.toString() ?? '';
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
      } else if (field.type == 'file') {
        data[fieldName] = _fileValues[fieldName] ?? '';
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

  Future<void> _uploadFileForField(String fieldName) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(withData: true);

      if (result == null || result.files.isEmpty) {
        return;
      }

      final fileBytes = result.files.single.bytes;
      final fileName = result.files.single.name;

      if (fileBytes == null) {
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final savedFilename = await CollectionService.uploadFile(
        fileBytes,
        fileName,
      );

      setState(() {
        _fileValues[fieldName] = savedFilename;
        _isUploading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File uploaded successfully to server!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      log('File upload error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                value: _checkboxValues[fieldName] ?? false,
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
      case 'file':
        return InputDecorator(
          decoration: InputDecoration(
            labelText: fieldName,
            suffixText: required ? '*' : '',
            border: const OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _fileValues[fieldName]?.isNotEmpty == true
                      ? _fileValues[fieldName]!
                      : 'No file selected',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _fileValues[fieldName]?.isNotEmpty == true
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () => _uploadFileForField(fieldName),
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Upload'),
              ),
            ],
          ),
        );
      case 'number':
        return TextFormField(
          controller: _controllers[fieldName],
          decoration: InputDecoration(
            labelText: fieldName,
            suffixText: required ? '*' : '',
            border: const OutlineInputBorder(),
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
            border: const OutlineInputBorder(),
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
                child: _buildFieldInput(field.name, field.type, field.required),
              );
            })
            .toList(),
      ),
    );
  }
}
