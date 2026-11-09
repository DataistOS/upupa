// upupa_dart/test/auth_service_test.dart
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upupa_dart/upupa_dart.dart';

void main() {
  group('AuthService Unit Tests', () {
    test('login success stores tokens and user record', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            '{"token": "mock_jwt_token", "refresh_token": "mock_refresh_token", "record": {"id": "123", "email": "test@example.com"}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = UpupaClient(
        'http://127.0.0.1:8090',
        httpClient: mockClient,
      );

      final result = await client.auth.login('test@example.com', 'password123');

      expect(result['token'], equals('mock_jwt_token'));
      expect(client.authStore.token, equals('mock_jwt_token'));
      expect(client.authStore.refreshToken, equals('mock_refresh_token'));
      expect(client.authStore.isValid, isTrue);
    });

    test('refresh token updates access token successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/refresh') {
          return http.Response(
            '{"token": "new_jwt_token", "refresh_token": "new_refresh_token"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = UpupaClient(
        'http://127.0.0.1:8090',
        httpClient: mockClient,
      );
      client.authStore.save('old_token', 'old_refresh_token', {'id': '123'});

      final result = await client.auth.refreshToken();

      expect(result['token'], equals('new_jwt_token'));
      expect(client.authStore.token, equals('new_jwt_token'));
      expect(client.authStore.refreshToken, equals('new_refresh_token'));
    });

    test('getOAuthUrl returns correct redirect provider url', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/oauth2/url' &&
            request.url.queryParameters['provider'] == 'google') {
          return http.Response(
            '{"url": "https://accounts.google.com/o/oauth2/v2/auth?client_id=test"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = UpupaClient(
        'http://127.0.0.1:8090',
        httpClient: mockClient,
      );

      final url = await client.auth.getOAuthUrl('google');
      expect(url, contains('accounts.google.com'));
    });

    test('requestOtp and authWithOtp work successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/otp-request') {
          return http.Response(
            '{"message": "OTP code sent successfully"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/auth/otp-login') {
          return http.Response(
            '{"token": "otp_jwt_token", "refresh_token": "otp_refresh_token", "record": {"email": "test@example.com"}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = UpupaClient(
        'http://127.0.0.1:8090',
        httpClient: mockClient,
      );

      final reqResult = await client.auth.requestOtp('test@example.com');
      expect(reqResult['message'], equals('OTP code sent successfully'));

      final loginResult = await client.auth.authWithOtp(
        'test@example.com',
        '123456',
      );
      expect(loginResult['token'], equals('otp_jwt_token'));
      expect(client.authStore.token, equals('otp_jwt_token'));
      expect(client.authStore.isValid, isTrue);
    });
  });
}
