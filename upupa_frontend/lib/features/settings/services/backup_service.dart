// upupa_frontend/lib/features/settings/services/backup_service.dart
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const String _baseUrl = 'http://127.0.0.1:8888/api/v1';

  Future<void> downloadBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final uri = Uri.parse('$_baseUrl/backup');
      final response = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        log('Backup downloaded successfully, size: ${bytes.length} bytes');

      } else {
        throw Exception('Failed to download backup: ${response.statusCode}');
      }
    } catch (e) {
      log('Backup error: $e');
      rethrow;
    }
  }
}