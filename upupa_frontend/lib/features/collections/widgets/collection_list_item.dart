// upupa_frontend/lib/features/collections/widgets/collection_list_item.dart
import 'package:flutter/material.dart';

import '../models/collection.dart';

class CollectionListItem extends StatelessWidget {
  final Collection collection;
  final VoidCallback onRecordsTap;
  final VoidCallback onSchemaEdit;
  final VoidCallback onRulesEdit;
  final VoidCallback onDelete;

  const CollectionListItem({
    super.key,
    required this.collection,
    required this.onRecordsTap,
    required this.onSchemaEdit,
    required this.onRulesEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = Text(
      'Records: ${collection.recordCount} | Fields: ${collection.schema.length}',
    );

    Widget? trailingWidget;
    if (collection.system) {
      trailingWidget = const Icon(Icons.arrow_forward_ios, size: 16);
    } else {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.code_outlined, size: 20, color: Colors.blue),
            tooltip: 'Edit Schema',
            onPressed: onSchemaEdit,
          ),
          IconButton(
            icon: const Icon(Icons.rule, size: 20, color: Colors.purple),
            tooltip: 'Edit Rules',
            onPressed: onRulesEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            tooltip: 'Delete Collection',
            onPressed: onDelete,
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      );
    }

    return ListTile(
      title: Text(
        collection.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: subtitle,
      onTap: onRecordsTap,
      trailing: trailingWidget,
    );
  }
}
