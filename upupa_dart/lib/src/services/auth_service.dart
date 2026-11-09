// upupa_dart/lib/src/services/auth_service.dart
import 'base_service.dart';
import '../client.dart';

class AuthService extends BaseService {
  AuthService(UpupaClient client) : super(client);

  Future<dynamic> login(String email, String password) async {
    final response = await client.sendPost(
      '/api/v1/login',
      body: {'email': email, 'password': password},
    );

    final data = handleResponse(response) as Map<String, dynamic>;

    if (data.containsKey('token')) {
      final token = data['token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      final record = data['record'] as Map<String, dynamic>?;

      client.authStore.save(token, refreshToken, record);
    }

    return data;
  }

  Future<dynamic> register(Map<String, dynamic> userData) async {
    final response = await client.sendPost('/api/v1/register', body: userData);

    return handleResponse(response) as Map<String, dynamic>;
  }

  Future<dynamic> refreshToken() async {
    final currentRefreshToken = client.authStore.refreshToken;
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      throw Exception('No refresh token available');
    }

    final response = await client.sendPost(
      '/api/auth/refresh',
      body: {'refresh_token': currentRefreshToken},
    );

    final data = handleResponse(response) as Map<String, dynamic>;

    if (data.containsKey('token')) {
      final newToken = data['token'] as String;
      final newRefreshToken = data.containsKey('refresh_token')
          ? data['refresh_token'] as String
          : currentRefreshToken;

      client.authStore.save(newToken, newRefreshToken, client.authStore.record);
    }

    return data;
  }

  Future<String> getOAuthUrl(String provider) async {
    final response = await client.sendGet(
      '/api/auth/oauth2/url?provider=$provider',
    );

    final data = handleResponse(response) as Map<String, dynamic>;
    return data['url'] as String;
  }

  Future<dynamic> authWithOAuth2(String provider, String code) async {
    final response = await client.sendPost(
      '/api/auth/oauth2/login',
      body: {'provider': provider, 'code': code},
    );

    final data = handleResponse(response) as Map<String, dynamic>;

    if (data.containsKey('token')) {
      final token = data['token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      final record = data['record'] as Map<String, dynamic>?;

      client.authStore.save(token, refreshToken, record);
    }

    return data;
  }

  Future<dynamic> requestOtp(String email) async {
    final response = await client.sendPost(
      '/api/v1/auth/otp-request',
      body: {'email': email},
    );

    return handleResponse(response);
  }

  Future<dynamic> authWithOtp(String email, String code) async {
    final response = await client.sendPost(
      '/api/v1/auth/otp-login',
      body: {'email': email, 'code': code},
    );

    final data = handleResponse(response) as Map<String, dynamic>;

    if (data.containsKey('token')) {
      final token = data['token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      final record = data['record'] as Map<String, dynamic>?;

      client.authStore.save(token, refreshToken, record);
    }

    return data;
  }

  Future<dynamic> setupMfa() async {
    final response = await client.sendPost('/api/v1/auth/mfa/setup');

    return handleResponse(response) as Map<String, dynamic>;
  }

  Future<dynamic> verifyMfa(String email, String code) async {
    final response = await client.sendPost(
      '/api/v1/auth/mfa/verify',
      body: {'email': email, 'code': code},
    );

    return handleResponse(response) as Map<String, dynamic>;
  }

  Future<dynamic> impersonate(String userId) async {
    final response = await client.sendPost(
      '/api/v1/admins/impersonate',
      body: {'user_id': userId},
    );

    final data = handleResponse(response) as Map<String, dynamic>;

    if (data.containsKey('token')) {
      final token = data['token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      final record = data['record'] as Map<String, dynamic>?;

      client.authStore.save(token, refreshToken, record);
    }

    return data;
  }

  void logout() {
    client.authStore.clear();
  }

  bool get isAuthenticated => client.authStore.isValid;
}
