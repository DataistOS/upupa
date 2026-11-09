// upupa_dart/lib/src/services/collection_service.dart
import 'base_service.dart';
import '../client.dart';
import '../models/collection.dart';
import '../models/field.dart';

class CollectionService extends BaseService {
  CollectionService(UpupaClient client) : super(client);

  Future<List<Collection>> getCollections() async {
    final response = await client.sendGet('/api/collections');
    final data = handleResponse(response);

    if (data is List) {
      return data.map((jsonItem) => Collection.fromJson(jsonItem)).toList();
    }
    return [];
  }

  Future<Collection> createCollection(String name) async {
    final response = await client.sendPost(
      '/api/collections',
      body: {'name': name},
    );
    final data = handleResponse(response);
    return Collection.fromJson(data);
  }

  Future<Collection> updateSchema(
    String collectionName,
    List<Field> schema,
  ) async {
    final response = await client.sendPost(
      '/api/collections/$collectionName',
      body: {'schema': schema.map((f) => f.toJson()).toList()},
    );
    final data = handleResponse(response);
    return Collection.fromJson(data);
  }

  Future<void> deleteCollection(String collectionName) async {
    final response = await client.sendDelete(
      '/api/collections/$collectionName',
    );
    handleResponse(response);
  }
}
