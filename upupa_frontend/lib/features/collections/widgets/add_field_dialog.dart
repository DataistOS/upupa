// upupa_frontend/lib/features/collections/widgets/add_field_dialog.dart
import 'package:flutter/material.dart';

import '../models/field.dart';
import '../models/collection.dart';

class AddFieldDialog extends StatefulWidget {
  final List<Field> existingFields;
  final List<Collection> availableCollections;

  const AddFieldDialog({
    super.key,
    required this.existingFields,
    required this.availableCollections,
  });

  @override
  State<AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<AddFieldDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _type = 'string';
  bool _required = false;
  String? _selectedCollectionId;

  void _addField() {
    if (_formKey.currentState?.validate() ?? false) {
      final newField = Field(
        name: _nameController.text.trim(),
        type: _type,
        required: _required,
        collectionId: _type == 'relation' ? _selectedCollectionId : null,
      );
      Navigator.of(context).pop(newField);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required.';
    }
    final name = value.trim();
    if (widget.existingFields.any((field) => field.name == name)) {
      return 'A field with this name already exists.';
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(name)) {
      return 'Only lowercase letters, numbers, and underscores are allowed.';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Field'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Field Name'),
              validator: _validateName,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Field Type'),
              items: <String>['string', 'number', 'boolean', 'file', 'relation']
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  })
                  .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _type = newValue;
                    if (_type != 'relation') {
                      _selectedCollectionId = null;
                    } else if (_selectedCollectionId == null &&
                        widget.availableCollections.isNotEmpty) {
                      _selectedCollectionId =
                          widget.availableCollections.first.id;
                    }
                  });
                }
              },
            ),
            if (_type == 'relation') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCollectionId,
                decoration: const InputDecoration(
                  labelText: 'Target Collection',
                ),
                items: widget.availableCollections.map((col) {
                  return DropdownMenuItem<String>(
                    value: col.id,
                    child: Text(col.name),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCollectionId = newValue;
                  });
                },
                validator: (value) {
                  if (_type == 'relation' && (value == null || value.isEmpty)) {
                    return 'Please select a target collection.';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Required:'),
                Checkbox(
                  value: _required,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _required = newValue ?? false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _addField, child: const Text('Add Field')),
      ],
    );
  }
}
