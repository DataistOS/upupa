// upupa_frontend/lib/features/collections/pages/record_list_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';

import '../models/collection.dart';
import '../models/record.dart';
import '../services/collection_service.dart';
import '../services/realtime_service.dart';
import '../widgets/record_list_item.dart';
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
  final RealtimeService _realtimeService = RealtimeService();

  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = '';

  int _currentPage = 1;
  final int _perPage = 15;
  bool _isTableView = false;

  @override
  void initState() {
    super.initState();
    _service = CollectionService(widget.collection.name);
    _fetchRecords();
    _initRealtime();
  }

  @override
  void dispose() {
    _realtimeService.disconnect();
    _searchController.dispose();
    super.dispose();
  }

  void _initRealtime() {
    _realtimeService.connect(
      onEvent: (event, collectionName, data) {
        if (collectionName == widget.collection.name) {
          log('Realtime event received: $event on collection $collectionName');
          _fetchRecords();
        }
      },
      onError: (error) {
        log('Realtime error: $error');
      },
    );
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

  void _changePage(int newPage) {
    if (newPage < 1) return;
    setState(() {
      _currentPage = newPage;
    });
    _fetchRecords();
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
            icon: Icon(_isTableView ? Icons.view_list : Icons.table_chart),
            tooltip: _isTableView
                ? 'Switch to List View'
                : 'Switch to Table View',
            onPressed: () {
              setState(() {
                _isTableView = !_isTableView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchRecords,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
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
                      _currentPage = 1;
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
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No records found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                } else {
                  final records = snapshot.data!;
                  return _isTableView
                      ? _buildDataTable(records)
                      : _buildListView(records);
                }
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page $_currentPage',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _currentPage > 1
                          ? () => _changePage(_currentPage - 1)
                          : null,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Previous'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _changePage(_currentPage + 1),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ],
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

  Widget _buildListView(List<Record> records) {
    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: records.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = records[index];
        return RecordListItem(
          collection: widget.collection,
          record: record,
          onEditTap: (rec) => _navigateToRecordDetail(record: rec),
          onDeleteTap: (rec) => _deleteRecord(rec.id),
        );
      },
    );
  }

  Widget _buildDataTable(List<Record> records) {
    final fields = widget.collection.schema;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(
              label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...fields.map(
              (f) => DataColumn(
                label: Text(
                  f.name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: records.map((record) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    record.id.length > 8
                        ? '${record.id.substring(0, 8)}...'
                        : record.id,
                  ),
                ),
                ...fields.map((f) {
                  final val = record.data[f.name];
                  return DataCell(Text(val?.toString() ?? '-'));
                }),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () =>
                            _navigateToRecordDetail(record: record),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () => _deleteRecord(record.id),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
