// upupa_frontend/lib/features/collections/widgets/schema_field_tile.dart
import 'package:flutter/material.dart';

import '../models/field.dart';

class SchemaFieldTile extends StatelessWidget {
  final Field field;
  final VoidCallback onDelete;

  const SchemaFieldTile({
    super.key,
    required this.field,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String defaultValueText = field.defaultValue != null
        ? ' | Default: ${field.defaultValue.toString()}'
        : '';

    final String title = field.name[0].toUpperCase() + field.name.substring(1);

    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        'Type: ${field.type} | Required: ${field.required ? 'Yes' : 'No'}$defaultValueText',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
        tooltip: 'Delete Field',
      ),
    );
  }
}
