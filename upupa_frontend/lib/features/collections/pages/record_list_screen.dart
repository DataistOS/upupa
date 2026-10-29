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

  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = '';
  int _currentPage = 1;
  final int _perPage = 30;

  @override
  void initState() {
    super.initState();
    _service = CollectionService(widget.collection.name);
    _fetchRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchRecords() {
    setState(() {
      String? filterParam;
      if (_currentFilter.isNotEmpty && widget.collection.schema.isNotEmpty) {
        final firstField = widget.collection.schema.first.name;
        filterParam = "$firstField ~ '$_currentFilter'";
      }

      _recordsFuture = _service.getRecords(
        page: _currentPage,
        perPage: _perPage,
        filter: filterParam,
      );
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRecords),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search in records...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _currentFilter = '';
                    });
                    _fetchRecords();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  _currentFilter = value.trim();
                  _currentPage = 1;
                });
                _fetchRecords();
              },
            ),
          ),
          // لیست رکوردها
          Expanded(
            child: FutureBuilder<List<Record>>(
              future: _recordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  log('Error loading records: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error loading records: ${snapshot.error.toString()}',
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No records found.'));
                } else {
                  final records = snapshot.data!;
                  return ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final displayValue = widget.collection.schema.isNotEmpty
                          ? (record.data[widget.collection.schema.first.name] ??
                                record.id)
                          : record.id;

                      return ListTile(
                        title: Text(displayValue.toString()),
                        subtitle: Text('ID: ${record.id}'),
                        onTap: () => _navigateToRecordDetail(record: record),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () =>
                                  _navigateToRecordDetail(record: record),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToRecordDetail(),
        tooltip: 'Create New Record',
        child: const Icon(Icons.add),
      ),
    );
  }
}
