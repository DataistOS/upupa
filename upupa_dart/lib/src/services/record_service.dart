// upupa_dart/lib/src/services/record_service.dart
import 'base_service.dart';
import '../client.dart';
import '../models/record.dart';

class RecordService extends BaseService {
  RecordService(UpupaClient client) : super(client);

  Future<List<Record>> getList(
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
      '/api/v1/collections/$collectionName/records',
    ).replace(queryParameters: queryParams);

    final response = await client.sendGet(uri.toString());
    final data = handleResponse(response);

    if (data is List) {
      return data.map((jsonItem) => Record.fromJson(jsonItem)).toList();
    }
    return [];
  }

  Future<Record> getOne(String collectionName, String recordId) async {
    final response = await client.sendGet(
      '/api/v1/collections/$collectionName/records/$recordId',
    );
    final data = handleResponse(response);
    return Record.fromJson(data);
  }

  Future<Record> create(
    String collectionName,
    Map<String, dynamic> bodyData,
  ) async {
    final response = await client.sendPost(
      '/api/v1/collections/$collectionName/records',
      body: bodyData,
    );
    final data = handleResponse(response);
    return Record.fromJson(data);
  }

  Future<Record> update(
    String collectionName,
    String recordId,
    Map<String, dynamic> bodyData,
  ) async {
    final response = await client.sendPost(
      '/api/v1/collections/$collectionName/records/$recordId',
      body: bodyData,
    );
    final data = handleResponse(response);
    return Record.fromJson(data);
  }

  Future<void> delete(String collectionName, String recordId) async {
    final response = await client.sendDelete(
      '/api/v1/collections/$collectionName/records/$recordId',
    );
    handleResponse(response);
  }
}
