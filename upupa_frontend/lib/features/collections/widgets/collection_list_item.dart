// upupa_frontend/lib/features/collections/widgets/collection_list_item.dart
import 'package:flutter/material.dart';

import '../models/collection.dart';

class CollectionListItem extends StatelessWidget {
  final Collection collection;
  final bool isPinned;
  final VoidCallback onRecordsTap;
  final VoidCallback onSchemaEdit;
  final VoidCallback onRulesEdit;
  final VoidCallback onRename;
  final VoidCallback onPinToggle;
  final VoidCallback onDelete;

  const CollectionListItem({
    super.key,
    required this.collection,
    this.isPinned = false,
    required this.onRecordsTap,
    required this.onSchemaEdit,
    required this.onRulesEdit,
    required this.onRename,
    required this.onPinToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        collection.system ? Icons.lock_outline : Icons.folder_outlined,
        color: collection.system ? Colors.grey : Colors.blueAccent,
        size: 20,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              collection.name,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPinned) ...[
            const SizedBox(width: 6),
            const Icon(Icons.push_pin, size: 14, color: Colors.amber),
          ],
        ],
      ),
      onTap: onRecordsTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.white54),
            tooltip: 'Actions',
            onSelected: (value) {
              switch (value) {
                case 'pin':
                  onPinToggle();
                  break;
                case 'rename':
                  onRename();
                  break;
                case 'schema':
                  onSchemaEdit();
                  break;
                case 'rules':
                  onRulesEdit();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(
                      isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Text(isPinned ? 'Unpin' : 'Pin to top'),
                  ],
                ),
              ),
              if (!collection.system) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Rename'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'schema',
                  child: Row(
                    children: [
                      Icon(Icons.code_outlined, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit Schema'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rules',
                  child: Row(
                    children: [
                      Icon(Icons.rule, size: 18, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Edit Rules'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white38),
        ],
      ),
    );
  }
}
