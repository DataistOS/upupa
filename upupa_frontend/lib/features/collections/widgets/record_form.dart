// upupa_frontend/lib/features/collections/widgets/record_form.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/collection.dart';
import '../models/record.dart';
import '../services/collection_service.dart';

import 'fields/text_field_widget.dart';
import 'fields/number_field_widget.dart';
import 'fields/bool_field_widget.dart';
import 'fields/date_field_widget.dart';
import 'fields/select_field_widget.dart';
import 'fields/file_field_widget.dart';
import 'fields/relation_field_widget.dart';
import 'fields/geopoint_field_widget.dart';
import 'fields/json_field_widget.dart';

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
  final Map<String, String?> _relationValues = {};
  final Map<String, String?> _selectValues = {};
  final Map<String, List<Record>> _targetRecordsCache = {};
  final Map<String, bool> _loadingRelations = {};

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadRelationTargetRecords();
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

      if (field.type == 'boolean' || field.type == 'bool') {
        _checkboxValues[key] = initialValue as bool? ?? false;
      } else if (field.type == 'file') {
        _fileValues[key] = initialValue?.toString() ?? '';
      } else if (field.type == 'relation') {
        _relationValues[key] = initialValue?.toString();
      } else if (field.type == 'select') {
        _selectValues[key] = initialValue?.toString();
      } else {
        _controllers[key] = TextEditingController(
          text: initialValue?.toString() ?? '',
        );
      }
    }
  }

  Future<void> _loadRelationTargetRecords() async {
    for (var field in widget.collection.schema) {
      if (field.type == 'relation' && field.collectionId != null) {
        final targetCollId = field.collectionId!;
        setState(() {
          _loadingRelations[field.name] = true;
        });

        try {
          final records = await CollectionService.getRecordsForCollection(
            targetCollId,
          );
          setState(() {
            _targetRecordsCache[field.name] = records;
            _loadingRelations[field.name] = false;
          });
        } catch (e) {
          log('Error loading target records for relation ${field.name}: $e');
          setState(() {
            _loadingRelations[field.name] = false;
          });
        }
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

      if (field.type == 'boolean' || field.type == 'bool') {
        data[fieldName] = _checkboxValues[fieldName] ?? false;
      } else if (field.type == 'file') {
        data[fieldName] = _fileValues[fieldName] ?? '';
      } else if (field.type == 'relation') {
        data[fieldName] = _relationValues[fieldName];
      } else if (field.type == 'select') {
        data[fieldName] = _selectValues[fieldName] ?? '';
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
    if (required && (value == null || value.trim().isEmpty)) {
      return 'This field is required.';
    }
    if (value != null && value.isNotEmpty) {
      if (type == 'number') {
        if (double.tryParse(value) == null) {
          return 'Must be a valid number.';
        }
      } else if (type == 'email') {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Must be a valid email address.';
        }
      } else if (type == 'url') {
        final urlRegex = RegExp(r'^(http|https):\/\/[^ "]+$');
        if (!urlRegex.hasMatch(value)) {
          return 'Must be a valid URL (e.g. https://example.com).';
        }
      }
    }
    return null;
  }

  Widget _buildFieldInput(var field) {
    final fieldName = field.name;
    final type = field.type;
    final required = field.required;
    final options = field.options ?? {};

    switch (type) {
      case 'boolean':
      case 'bool':
        return BoolFieldWidget(
          name: fieldName,
          required: required,
          value: _checkboxValues[fieldName] ?? false,
          onChanged: (newValue) {
            if (!mounted) return;
            setState(() {
              _checkboxValues[fieldName] = newValue;
            });
          },
        );

      case 'file':
        return FileFieldWidget(
          name: fieldName,
          required: required,
          fileName: _fileValues[fieldName] ?? '',
          isUploading: _isUploading,
          onUploadPressed: () => _uploadFileForField(fieldName),
        );

      case 'relation':
        return RelationFieldWidget(
          name: fieldName,
          required: required,
          selectedRecordId: _relationValues[fieldName],
          targetRecords: _targetRecordsCache[fieldName] ?? [],
          isLoading: _loadingRelations[fieldName] ?? false,
          onChanged: (newValue) {
            setState(() {
              _relationValues[fieldName] = newValue;
            });
          },
        );

      case 'select':
        return SelectFieldWidget(
          name: fieldName,
          required: required,
          value: _selectValues[fieldName],
          options: options,
          onChanged: (newValue) {
            setState(() {
              _selectValues[fieldName] = newValue;
            });
          },
        );

      case 'number':
        return NumberFieldWidget(
          name: fieldName,
          required: required,
          controller: _controllers[fieldName]!,
          validator: _validator,
        );

      case 'email':
      case 'url':
      case 'editor':
      case 'text':
      case 'string':
        return TextFieldWidget(
          name: fieldName,
          type: type,
          required: required,
          controller: _controllers[fieldName]!,
          validator: _validator,
        );

      case 'date':
      case 'autodate':
        return DateFieldWidget(
          name: fieldName,
          type: type,
          required: required,
          controller: _controllers[fieldName]!,
          validator: _validator,
        );

      case 'geopoint':
        return GeoPointFieldWidget(
          name: fieldName,
          required: required,
          controller: _controllers[fieldName]!,
          validator: _validator,
        );

      case 'json':
        return JsonFieldWidget(
          name: fieldName,
          required: required,
          controller: _controllers[fieldName]!,
          validator: _validator,
        );

      default:
        return TextFieldWidget(
          name: fieldName,
          type: 'text',
          required: required,
          controller: _controllers[fieldName]!,
          validator: _validator,
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
                child: _buildFieldInput(field),
              );
            })
            .toList(),
      ),
    );
  }
}
