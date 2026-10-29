// upupa_frontend/lib/features/collections/pages/collection_schema_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';

import '../models/collection.dart';
import '../models/field.dart';
import '../services/collection_service.dart';
import '../widgets/add_field_dialog.dart';
import '../widgets/schema_field_tile.dart';

class CollectionSchemaScreen extends StatefulWidget {
  final Collection collection;
  final VoidCallback onUpdate;

  const CollectionSchemaScreen({
    super.key,
    required this.collection,
    required this.onUpdate,
  });

  @override
  State<CollectionSchemaScreen> createState() => _CollectionSchemaScreenState();
}

class _CollectionSchemaScreenState extends State<CollectionSchemaScreen> {
  late List<Field> _fields;
  late CollectionService _service;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fields = List.from(widget.collection.schema);
    _service = CollectionService(widget.collection.name);
  }

  void _onFieldAdded(Field newField) {
    if (!mounted) return;
    setState(() {
      _fields.add(newField);
    });
  }

  void _deleteField(int index) {
    if (!mounted) return;
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete the field "${_fields[index].name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _fields.removeAt(index);
        });
      }
    });
  }

  void _showAddFieldDialog() {
    showDialog<Field>(
      context: context,
      builder: (context) => AddFieldDialog(existingFields: _fields),
    ).then((newField) {
      if (newField != null) {
        _onFieldAdded(newField);
      }
    });
  }

  void _saveSchema() async {
    if (_isSaving) return;

    if (!mounted) return;
    setState(() {
      _isSaving = true;
    });

    try {
      await _service.updateCollectionSchema(_fields);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schema updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onUpdate();
    } catch (e) {
      log('Schema update error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.collection.name} Schema'),
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: widget.collection.system || _isSaving
                      ? null
                      : _saveSchema,
                ),
        ],
      ),
      body: widget.collection.system
          ? const Center(
              child: Text(
                'Cannot modify the schema of system collections.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          : ListView.builder(
              itemCount: _fields.length,
              itemBuilder: (context, index) {
                final field = _fields[index];
                return SchemaFieldTile(
                  field: field,
                  onDelete: () => _deleteField(index),
                );
              },
            ),
      floatingActionButton: widget.collection.system
          ? null
          : FloatingActionButton(
              onPressed: _showAddFieldDialog,
              tooltip: 'Add Field',
              child: const Icon(Icons.add),
            ),
    );
  }
}
