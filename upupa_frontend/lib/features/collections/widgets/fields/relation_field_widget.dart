// upupa_frontend/lib/features/collections/widgets/fields/relation_field_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/record.dart';
import 'base_field_widget.dart';

class RelationFieldWidget extends StatelessWidget {
  final String name;
  final bool required;
  final String? selectedRecordId;
  final List<Record> targetRecords;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  const RelationFieldWidget({
    super.key,
    required this.name,
    required this.required,
    required this.selectedRecordId,
    required this.targetRecords,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validValue = targetRecords.any((r) => r.id == selectedRecordId)
        ? selectedRecordId
        : null;

    return BaseFieldLayout(
      label: name,
      required: required,
      child: DropdownButtonFormField<String>(
        value: validValue,
        decoration: InputDecoration(
          labelText: '$name (Relation)',
          suffixText: required ? '*' : '',
          border: const OutlineInputBorder(),
        ),
        items: targetRecords.map<DropdownMenuItem<String>>((rec) {
          String label = rec.id;
          if (rec.data.isNotEmpty) {
            for (var val in rec.data.values) {
              if (val != null) {
                label = val.toString();
                break;
              }
            }
          }
          return DropdownMenuItem<String>(
            value: rec.id,
            child: Text(
              '$label (${rec.id.substring(0, min(6, rec.id.length))})',
            ),
          );
        }).toList(),
        hint: isLoading
            ? const Text('Loading items...')
            : const Text('Select related record'),
        onChanged: onChanged,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'This relation field is required.';
          }
          return null;
        },
      ),
    );
  }
}
