// upupa_frontend/lib/features/collections/widgets/record_list_item.dart
import 'package:flutter/material.dart';
import '../models/record.dart';
import '../models/collection.dart';

typedef RecordActionCallback = void Function(Record record);

class RecordListItem extends StatelessWidget {
  final Collection collection;
  final Record record;
  final RecordActionCallback onEditTap;
  final RecordActionCallback onDeleteTap;

  const RecordListItem({
    super.key,
    required this.collection,
    required this.record,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  String safeToString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value.isEmpty ? defaultValue : value;
    if (value is num) return value.toString();
    if (value is bool) return value ? 'True' : 'False';
    if (value is DateTime) return value.toString().split(' ').first;
    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final titleField = collection.schema.firstWhere(
      (f) => f.type == 'string',
      orElse: () => collection.schema.first,
    );

    final subtitleWidgets = collection.schema
        .where((f) => f.name != titleField.name && f.name != 'id')
        .take(2)
        .map((field) {
          final value = record.data[field.name];
          final displayValue = safeToString(value, 'N/A');

          return Text(
            '${field.name[0].toUpperCase() + field.name.substring(1)}: $displayValue',
            style: Theme.of(context).textTheme.bodySmall,
          );
        })
        .toList();

    subtitleWidgets.addAll([
      Text(
        'Created: ${safeToString(record.created, 'N/A')}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        'Updated: ${safeToString(record.updated, 'N/A')}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ]);

    final titleValue = safeToString(
      record.data[titleField.name],
      'Record ID: ${record.id.substring(0, 8)}...',
    );

    return ListTile(
      title: Text(
        titleValue,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: subtitleWidgets,
      ),
      onTap: () => onEditTap(record),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => onDeleteTap(record),
        tooltip: 'Delete Record',
      ),
    );
  }
}

extension on Record {
  get updated => null;
}
