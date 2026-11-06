// upupa_dart/test/collection_service_test.dart
import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upupa_dart/upupa_dart.dart';

void main() {
  group('CollectionService Tests', () {
    test('getFullList returns list of Collection on success', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/collections');

        final mockResponse = [
          {
            'id': 'col123',
            'name': 'posts',
            'type': 'base',
            'system': false,
            'schema': [],
          },
        ];

        return http.Response(jsonEncode(mockResponse), 200);
      });

      final client = UpupaClient(
        'http://127.0.0.1:8090',
        httpClient: mockHttpClient,
      );

      final collections = await client.collections.getFullList();

      expect(collections.length, 1);
      expect(collections[0].id, 'col123');
      expect(collections[0].name, 'posts');
    });

    test(
      'create collection sends correct body and returns Collection',
      () async {
        final mockHttpClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/collections');

          final body = jsonDecode(request.body);
          expect(body['name'], 'comments');

          final mockResponse = {
            'id': 'col456',
            'name': 'comments',
            'type': 'base',
            'system': false,
            'schema': [],
          };

          return http.Response(jsonEncode(mockResponse), 200);
        });

        final client = UpupaClient(
          'http://127.0.0.1:8090',
          httpClient: mockHttpClient,
        );

        final newCollection = await client.collections.create({
          'name': 'comments',
          'type': 'base',
        });

        expect(newCollection.id, 'col456');
        expect(newCollection.name, 'comments');
      },
    );

    test('delete collection sends DELETE request successfully', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/collections/col123');

        return http.Response('', 204);
      });

      final client = UpupaClient(
        'http://127.0.0.1:8090',
        httpClient: mockHttpClient,
      );

      final success = await client.collections.delete('col123');

      expect(success, true);
    });

    test('getOne throws Exception on 400 Bad Request', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode({'message': 'Invalid collection id'}),
          400,
        );
      });

      final client = UpupaClient(
        'http://127.0.0.1:8090',
        httpClient: mockHttpClient,
      );

      expect(
        () async => await client.collections.getOne('invalid_id'),
        throwsA(isA<Exception>()),
      );
    });

    test('create throws Exception on 401 Unauthorized', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.method, 'POST');
        return http.Response(
          jsonEncode({'message': 'Unauthorized access'}),
          401,
        );
      });

      final client = UpupaClient(
        'http://127.0.0.1:8090',
        httpClient: mockHttpClient,
      );

      expect(
        () async => await client.collections.create({'name': 'test'}),
        throwsA(isA<Exception>()),
      );
    });
  });
}
