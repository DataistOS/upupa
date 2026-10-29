// upupa_frontend/lib/features/collections/services/collection_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/record.dart';
import '../models/collection.dart';
import '../models/field.dart';
import '../models/rule.dart';
import '../../auth/services/auth_service.dart';

const String _baseUrl = 'http://127.0.0.1:8888/api/v1';

class CollectionService {
  final String collectionName;
  final String _collectionUrl;

  CollectionService(this.collectionName)
    : _collectionUrl = '$_baseUrl/collections/$collectionName/records';

  static Map<String, String> _getHeaders({bool includeContentType = true}) {
    final authInstance = AuthService();
    final headers = <String, String>{};

    if (authInstance.token != null) {
      headers['Authorization'] = 'Bearer ${authInstance.token}';
    }

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  static Future<List<Collection>> getCollections() async {
    final uri = Uri.parse('$_baseUrl/collections');

    try {
      final response = await http.get(
        uri,
        headers: _getHeaders(includeContentType: false),
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body);

        return items.map((jsonItem) => Collection.fromJson(jsonItem)).toList();
      } else {
        throw Exception(
          'Failed to load collections. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  static Future<Collection> createCollection(String name) async {
    final uri = Uri.parse('$_baseUrl/collections');

    try {
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 201) {
        return Collection.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to create collection. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  static Future<List<Record>> getRecordsForCollection(
    String collectionName,
  ) async {
    final uri = Uri.parse('$_baseUrl/collections/$collectionName/records');

    try {
      final response = await http.get(
        uri,
        headers: _getHeaders(includeContentType: false),
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body);
        return items.map((jsonItem) => Record.fromJson(jsonItem)).toList();
      } else {
        throw Exception(
          'Failed to load records for collection $collectionName. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<void> deleteCollection() async {
    final uri = Uri.parse('$_baseUrl/collections/$collectionName');

    try {
      final response = await http.delete(
        uri,
        headers: _getHeaders(includeContentType: false),
      );

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Collection not found for deletion.');
      } else {
        throw Exception(
          'Failed to delete collection. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<Collection> updateCollectionSchema(List<Field> schema) async {
    final uri = Uri.parse('$_baseUrl/collections/$collectionName');

    try {
      final response = await http.patch(
        uri,
        headers: _getHeaders(),
        body: json.encode({'schema': schema.map((f) => f.toJson()).toList()}),
      );

      if (response.statusCode == 200) {
        return Collection.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Collection not found for schema update.');
      } else {
        throw Exception(
          'Failed to update schema. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<Collection> updateCollectionRules(List<Rule> rules) async {
    final uri = Uri.parse('$_baseUrl/collections/$collectionName');

    try {
      final response = await http.patch(
        uri,
        headers: _getHeaders(),
        body: json.encode({'rules': rules.map((r) => r.toJson()).toList()}),
      );

      if (response.statusCode == 200) {
        return Collection.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Collection not found for rules update.');
      } else {
        throw Exception(
          'Failed to update rules. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  // متد جدید برای آپلود فایل به سرور
  static Future<String> uploadFile(dynamic fileBytes, String filename) async {
    final uri = Uri.parse('$_baseUrl/files');

    try {
      var request = http.MultipartRequest('POST', uri);

      final authInstance = AuthService();
      if (authInstance.token != null) {
        request.headers['Authorization'] = 'Bearer ${authInstance.token}';
      }

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: filename),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['filename'] ?? '';
      } else {
        throw Exception(
          'Failed to upload file. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API for file upload: $e');
    }
  }

  Future<List<Record>> getRecords({
    int page = 1,
    int perPage = 30,
    String? sort,
    String? filter,
  }) async {
    final Uri baseUri = Uri.parse(_collectionUrl);

    final Map<String, String> queryParams = {
      'page': page.toString(),
      'perPage': perPage.toString(),
    };

    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }

    if (filter != null && filter.isNotEmpty) {
      queryParams['filter'] = filter;
    }

    final uri = baseUri.replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: _getHeaders(includeContentType: false),
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body);
        return items.map((jsonItem) => Record.fromJson(jsonItem)).toList();
      } else {
        throw Exception(
          'Failed to load records. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<Record> getRecord(String id) async {
    final uri = Uri.parse('$_collectionUrl/$id');

    try {
      final response = await http.get(
        uri,
        headers: _getHeaders(includeContentType: false),
      );

      if (response.statusCode == 200) {
        return Record.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Record not found.');
      } else {
        throw Exception(
          'Failed to load record. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<Record> createRecord(Map<String, dynamic> data) async {
    final uri = Uri.parse(_collectionUrl);

    try {
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return Record.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to create record. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<Record> updateRecord(String id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_collectionUrl/$id');

    try {
      final response = await http.patch(
        uri,
        headers: _getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return Record.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Record not found for update.');
      } else {
        throw Exception(
          'Failed to update record. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    final uri = Uri.parse('$_collectionUrl/$id');

    try {
      final response = await http.delete(
        uri,
        headers: _getHeaders(includeContentType: false),
      );

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Record not found for deletion.');
      } else {
        throw Exception(
          'Failed to delete record. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }
}
