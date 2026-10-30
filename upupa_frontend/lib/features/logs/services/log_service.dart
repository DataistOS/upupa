// upupa_frontend/lib/features/logs/services/log_service.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/request_log.dart';

class LogService {
  static const String baseUrl = 'http://localhost:8888/api/v1';

  static Future<List<RequestLog>> getLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/logs'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<RequestLog> logs = body
            .map((dynamic item) => RequestLog.fromJson(item))
            .toList();
        return logs;
      } else {
        throw Exception('Failed to load request logs: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching logs: $e');
      rethrow;
    }
  }
}
