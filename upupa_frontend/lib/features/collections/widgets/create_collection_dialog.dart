// upupa_frontend/lib/features/collections/widgets/create_collection_dialog.dart
import 'package:flutter/material.dart';

class CreateCollectionDialog extends StatefulWidget {
  const CreateCollectionDialog({super.key});

  @override
  State<CreateCollectionDialog> createState() => _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<CreateCollectionDialog> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _createCollection() {
    if (_formKey.currentState?.validate() ?? false) {
      final collectionName = _controller.text.trim();
      Navigator.of(context).pop(collectionName);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Collection'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Collection Name',
            hintText: 'e.g., products, users',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Name cannot be empty';
            }
            if (value.contains(RegExp(r'[^a-z0-9_]')) || value.isEmpty) {
              return 'Only lowercase letters, numbers, and underscores are allowed.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createCollection,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
