// upupa_frontend/lib/features/auth/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

const String _baseUrl = 'http://127.0.0.1:8888/api/v1';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  String? _token;
  User? _currentUser;
  bool _isAuthenticated = false;

  String? get token => _token;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _isAuthenticated;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    if (_token != null) {
      _isAuthenticated = true;
      _currentUser = User(
        id: 'unknown_local_id',
        email: 'local_user@upupa.local',
        created: DateTime.now(),
        updated: DateTime.now(),
        isAdmin: true,
      );
    }
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      final token = jsonResponse['token'] as String;
      _currentUser = User.fromJson(jsonResponse['user']);
      await _saveToken(token);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(
        errorBody['error'] ??
            'Registration failed with status ${response.statusCode}',
      );
    }
  }

  Future<void> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final token = jsonResponse['token'] as String;
      _currentUser = User.fromJson(jsonResponse['user']);
      await _saveToken(token);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(
        errorBody['error'] ?? 'Login failed with status ${response.statusCode}',
      );
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }

  Future<void> requestPasswordReset(String email) async {
    final uri = Uri.parse('$_baseUrl/auth/password-reset');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw Exception(
        errorBody['error'] ??
            'Failed to request password reset (status ${response.statusCode})',
      );
    }
  }

  Future<void> confirmPasswordReset(String token, String newPassword) async {
    final uri = Uri.parse('$_baseUrl/auth/password-reset-confirm');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': token, 'new_password': newPassword}),
    );

    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw Exception(
        errorBody['error'] ??
            'Failed to reset password (status ${response.statusCode})',
      );
    }
  }
}
