// upupa_dart/lib/src/services/collection_service.dart
import 'base_service.dart';
import '../client.dart';
import '../models/collection.dart';
import 'dart:convert';

class CollectionService extends BaseService {
  CollectionService(UpupaClient client) : super(client);

  Future<List<Collection>> getFullList({Map<String, String>? headers}) async {
    final response = await client.sendGet('/api/collections', headers: headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      List<dynamic> items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map && decoded.containsKey('items')) {
        items = decoded['items'] as List<dynamic>;
      } else {
        items = [];
      }

      return items
          .map((item) => Collection.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('خطا در دریافت لیست کولکشن‌ها: ${response.body}');
    }
  }

  Future<Collection> getOne(
    String idOrName, {
    Map<String, String>? headers,
  }) async {
    final response = await client.sendGet(
      '/api/collections/$idOrName',
      headers: headers,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return Collection.fromJson(decoded);
    } else {
      throw Exception('خطا در دریافت اطلاعات کولکشن: ${response.body}');
    }
  }

  Future<Collection> create(
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final response = await client.sendPost(
      '/api/collections',
      body: body,
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return Collection.fromJson(decoded);
    } else {
      throw Exception('خطا در ایجاد کولکشن: ${response.body}');
    }
  }

  Future<Collection> update(
    String idOrName,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final response = await client.sendPost(
      '/api/collections/$idOrName',
      body: body,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return Collection.fromJson(decoded);
    } else {
      throw Exception('خطا در ویرایش کولکشن: ${response.body}');
    }
  }

  Future<bool> delete(String idOrName, {Map<String, String>? headers}) async {
    final response = await client.sendDelete(
      '/api/collections/$idOrName',
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('خطا در حذف کولکشن: ${response.body}');
    }
  }
}
