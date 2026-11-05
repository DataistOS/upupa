// upupa_dart/test/service_test.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:upupa_dart/upupa_dart.dart';

void main() {
  group('AuthService & RecordService Mock Tests', () {
    test(
      'AuthService login sends correct request and parses response',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, equals('/api/auth/login'));
          expect(request.method, equals('POST'));

          final body = jsonDecode(request.body);
          expect(body['email'], equals('test@hedeh.ir'));
          expect(body['password'], equals('password123'));

          return http.Response(
            jsonEncode({
              'token': 'mock_jwt_token_123',
              'user': {'id': 'user_1', 'email': 'test@hedeh.ir'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = UpupaClient(
          'http://localhost:8090',
          httpClient: mockClient,
        );
        final authService = AuthService(client);

        final result = await authService.login('test@hedeh.ir', 'password123');

        expect(result['token'], equals('mock_jwt_token_123'));
        expect(client.authStore.token, equals('mock_jwt_token_123'));
        expect(client.authStore.isValid, isTrue);
      },
    );

    test(
      'RecordService update wraps data inside "data" key as backend expects',
      () async {
        final mockClient = MockClient((request) async {
          expect(
            request.url.path,
            equals('/api/collections/posts/records/rec_1'),
          );
          expect(request.method, equals('POST'));

          final body = jsonDecode(request.body);
          expect(body.containsKey('data'), isTrue);
          expect(body['data']['title'], equals('Updated Title'));

          return http.Response(
            jsonEncode({
              'id': 'rec_1',
              'data': {'title': 'Updated Title'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = UpupaClient(
          'http://localhost:8090',
          httpClient: mockClient,
        );
        final recordService = RecordService(client);

        final result = await recordService.update('posts', 'rec_1', {
          'title': 'Updated Title',
        });

        expect(result['id'], equals('rec_1'));
      },
    );
  });
}
