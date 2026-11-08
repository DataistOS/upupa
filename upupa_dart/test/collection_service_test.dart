// upupa_dart/test/collection_service_test.dart
import 'package:test/test.dart';
import 'package:upupa_dart/upupa_dart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('CollectionService Tests', () {
    test('getCollections returns list of collections on success', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/collections') {
          return http.Response(
            jsonEncode([
              {'id': '1', 'name': 'posts', 'schema': [], 'rules': []},
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = UpupaClient(
        'http://localhost:8090',
        httpClient: mockClient,
      );

      final collections = await client.collections.getCollections();

      expect(collections.length, 1);
      expect(collections[0].name, 'posts');
      client.dispose();
    });

    test('createCollection creates a collection successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/collections' &&
            request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'id': '2',
              'name': 'comments',
              'schema': [],
              'rules': [],
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = UpupaClient(
        'http://localhost:8090',
        httpClient: mockClient,
      );

      final collection = await client.collections.createCollection('comments');

      expect(collection.id, '2');
      expect(collection.name, 'comments');
      client.dispose();
    });

    test('deleteCollection deletes a collection successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/collections/posts' &&
            request.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response('Not Found', 404);
      });

      final client = UpupaClient(
        'http://localhost:8090',
        httpClient: mockClient,
      );

      expect(
        () => client.collections.deleteCollection('posts'),
        returnsNormally,
      );
      client.dispose();
    });
  });
}
