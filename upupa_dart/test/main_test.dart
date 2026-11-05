// upupa_dart/test/main_test.dart
import 'package:test/test.dart';
import 'package:upupa_dart/src/auth_store.dart';

void main() {
  group('AuthStore Tests', () {
    test('Initial state should be invalid (empty token)', () {
      final authStore = AuthStore();

      expect(authStore.token, isNull);
      expect(authStore.record, isNull);
      expect(authStore.isValid, isFalse);
    });

    test('Should save token and record correctly', () {
      final authStore = AuthStore();
      const testToken = 'mock_jwt_token_12345';
      final testRecord = {'id': 'user_1', 'email': 'test@example.com'};

      authStore.save(testToken, testRecord);

      expect(authStore.token, equals(testToken));
      expect(authStore.record, equals(testRecord));
      expect(authStore.isValid, isTrue);
    });

    test('Should clear credentials on logout', () {
      final authStore = AuthStore(token: 'some_token', record: {});
      expect(authStore.isValid, isTrue);

      authStore.clear();

      expect(authStore.token, isNull);
      expect(authStore.record, isNull);
      expect(authStore.isValid, isFalse);
    });
  });
}
