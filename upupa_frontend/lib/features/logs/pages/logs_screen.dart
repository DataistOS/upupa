// upupa_frontend/lib/features/logs/pages/logs_screen.dart
import 'package:flutter/material.dart';
import '../models/request_log.dart';
import '../services/log_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late Future<List<RequestLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  void _fetchLogs() {
    setState(() {
      _logsFuture = LogService.getLogs();
    });
  }

  Color _getStatusColor(int status) {
    if (status >= 200 && status < 300) {
      return Colors.green.shade100;
    } else if (status >= 400 && status < 500) {
      return Colors.orange.shade100;
    } else if (status >= 500) {
      return Colors.red.shade100;
    }
    return Colors.grey.shade100;
  }

  Color _getStatusTextColor(int status) {
    if (status >= 200 && status < 300) {
      return Colors.green.shade800;
    } else if (status >= 400 && status < 500) {
      return Colors.orange.shade800;
    } else if (status >= 500) {
      return Colors.red.shade800;
    }
    return Colors.grey.shade800;
  }

  // تعیین رنگ متد HTTP
  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Request logs'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF374151),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh logs',
            onPressed: _fetchLogs,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: FutureBuilder<List<RequestLog>>(
                  future: _logsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading logs: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No request logs found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final logs = snapshot.data!;

                    return ListView(
                      scrollDirection: Axis.vertical,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey.shade50,
                            ),
                            columns: const [
                              DataColumn(label: Text('Method')),
                              DataColumn(label: Text('URL')),
                              DataColumn(label: Text('Referer')),
                              DataColumn(label: Text('User IP')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Created')),
                            ],
                            rows: logs.map((log) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getMethodColor(
                                          log.method,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        log.method,
                                        style: TextStyle(
                                          color: _getMethodColor(log.method),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // آدرس URL
                                  DataCell(
                                    Text(
                                      log.url,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(log.referer)),
                                  DataCell(Text(log.ip)),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(log.status),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        log.status.toString(),
                                        style: TextStyle(
                                          color: _getStatusTextColor(
                                            log.status,
                                          ),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      log.createdAt
                                          .toLocal()
                                          .toString()
                                          .split('.')
                                          .first,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
