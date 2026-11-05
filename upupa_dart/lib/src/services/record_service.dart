// upupa_dart/lib/src/services/record_service.dart
import 'dart:async';

import 'base_service.dart';
import '../client.dart';

class RecordService extends BaseService {
  RecordService(UpupaClient client) : super(client);

  Future<dynamic> getList(
    String collectionName, {
    int page = 1,
    int perPage = 30,
    String? filter,
    String? sort,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'perPage': perPage.toString(),
      if (filter != null) 'filter': filter,
      if (sort != null) 'sort': sort,
    };

    final uri = Uri.parse(
      '/api/collections/$collectionName/records',
    ).replace(queryParameters: queryParams);

    final response = await client.sendGet(uri.toString());
    return handleResponse(response) as Map<String, dynamic>;
  }

  Future<dynamic> getOne(String collectionName, String recordId) async {
    final response = await client.sendGet(
      '/api/collections/$collectionName/records/$recordId',
    );
    return handleResponse(response) as Map<String, dynamic>;
  }

  Future<dynamic> create(
    String collectionName,
    Map<String, dynamic> bodyData,
  ) async {
    final response = await client.sendPost(
      '/api/collections/$collectionName/records',
      body: bodyData,
    );
    return handleResponse(response) as Map<String, dynamic>;
  }

  Future<dynamic> update(
    String collectionName,
    String recordId,
    Map<String, dynamic> bodyData,
  ) async {
    final response = await client.sendPost(
      '/api/collections/$collectionName/records/$recordId',
      body: {'data': bodyData},
    );
    return handleResponse(response) as Map<String, dynamic>;
  }

  Future<void> delete(String collectionName, String recordId) async {
    final response = await client.sendPost(
      '/api/collections/$collectionName/records/$recordId/delete',
    );
    handleResponse(response);
  }
}
