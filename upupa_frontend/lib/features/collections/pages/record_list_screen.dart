// upupa_frontend/lib/features/collections/pages/record_list_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';

import '../models/collection.dart';
import '../models/record.dart';
import '../services/collection_service.dart';
import 'record_detail_screen.dart';

class RecordListScreen extends StatefulWidget {
  final Collection collection;

  const RecordListScreen({super.key, required this.collection});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  late Future<List<Record>> _recordsFuture;
  late CollectionService _service;

  @override
  void initState() {
    super.initState();
    _service = CollectionService(widget.collection.name);
    _fetchRecords();
  }

  void _fetchRecords() {
    setState(() {
      _recordsFuture = _service.getRecords();
    });
  }

  void _navigateToRecordDetail({Record? record}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordDetailScreen(
          collection: widget.collection,
          recordId: record?.id,
        ),
      ),
    );
    if (result == true) {
      _fetchRecords();
    }
  }

  void _deleteRecord(String recordId) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this record?'),
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
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          await _service.deleteRecord(recordId);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchRecords();
        } catch (e) {
          log('Record deletion error: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete record: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.collection.name} Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRecords,
          ),
        ],
      ),
      body: FutureBuilder<List<Record>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            log('Error loading records: ${snapshot.error}');
            return Center(
              child: Text('Error loading records: ${snapshot.error.toString()}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No records found.'),
            );
          } else {
            final records = snapshot.data!;
            return ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final displayValue = record.data[widget.collection.schema.first.name] ?? record.id;

                return ListTile(
                  title: Text(displayValue.toString()),
                  subtitle: Text('ID: ${record.id}'),
                  onTap: () => _navigateToRecordDetail(record: record),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _navigateToRecordDetail(record: record),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _deleteRecord(record.id),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToRecordDetail(),
        tooltip: 'Create New Record',
        child: const Icon(Icons.add),
      ),
    );
  }
}