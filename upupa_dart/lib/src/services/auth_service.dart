// upupa_dart/lib/src/services/auth_service.dart
import 'base_service.dart';
import '../client.dart';

class AuthService extends BaseService {
  AuthService(UpupaClient client) : super(client);

  Future<dynamic> login(String email, String password) async {
    final response = await client.sendPost(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );

    final data = handleResponse(response) as Map<String, dynamic>;

    if (data.containsKey('token')) {
      final token = data['token'] as String;
      final record = data['record'] as Map<String, dynamic>?;

      client.authStore.save(token, record);
    }

    return data;
  }

  Future<dynamic> register(Map<String, dynamic> userData) async {
    final response = await client.sendPost(
      '/api/auth/register',
      body: userData,
    );

    return handleResponse(response) as Map<String, dynamic>;
  }

  void logout() {
    client.authStore.clear();
  }

  bool get isAuthenticated => client.authStore.isValid;
}
