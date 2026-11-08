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
  final TextEditingController _optionsController = TextEditingController();

  String _type = 'text';
  bool _required = false;
  String? _selectedCollectionId;

  final List<dynamic> _fieldTypesInfo = [
    {'type': 'text', 'icon': Icons.text_fields},
    {'type': 'number', 'icon': Icons.numbers},
    {'type': 'bool', 'icon': Icons.check_box},
    {'type': 'email', 'icon': Icons.email},
    {'type': 'url', 'icon': Icons.link},
    {'type': 'editor', 'icon': Icons.subject},
    {'type': 'date', 'icon': Icons.calendar_today},
    {'type': 'autodate', 'icon': Icons.update},
    {'type': 'select', 'icon': Icons.list},
    {'type': 'file', 'icon': Icons.attach_file},
    {'type': 'relation', 'icon': Icons.link_rounded},
    {'type': 'json', 'icon': Icons.code},
    {'type': 'geopoint', 'icon': Icons.map},
  ];

  void _addField() {
    if (_formKey.currentState?.validate() ?? false) {
      Map<String, dynamic>? options;
      if (_type == 'select') {
        final values = _optionsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        options = {'values': values};
      }

      final newField = Field(
        name: _nameController.text.trim(),
        type: _type,
        required: _required,
        collectionId: _type == 'relation' ? _selectedCollectionId : null,
        options: options,
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
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 420,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Field',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Field Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateName,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Field Type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _fieldTypesInfo.length,
                          itemBuilder: (context, index) {
                            final info = _fieldTypesInfo[index];
                            final typeName = info['type'] as String;
                            final icon = info['icon'] as IconData;
                            final isSelected = _type == typeName;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _type = typeName;
                                  if (_type != 'relation') {
                                    _selectedCollectionId = null;
                                  } else if (_selectedCollectionId == null &&
                                      widget.availableCollections.isNotEmpty) {
                                    _selectedCollectionId =
                                        widget.availableCollections.first.id;
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      icon,
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      typeName,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (_type == 'relation') ...[
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedCollectionId,
                            decoration: const InputDecoration(
                              labelText: 'Target Collection',
                              border: OutlineInputBorder(),
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
                              if (_type == 'relation' &&
                                  (value == null || value.isEmpty)) {
                                return 'Please select a target collection.';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (_type == 'select') ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _optionsController,
                            decoration: const InputDecoration(
                              labelText: 'Options (comma separated)',
                              hintText: 'Option1, Option2, Option3',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_type == 'select' &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please provide options for select field.';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: _required,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  _required = newValue ?? false;
                                });
                              },
                            ),
                            const Text('Required field'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addField,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Add Field'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
