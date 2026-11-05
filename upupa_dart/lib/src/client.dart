// upupa_dart/lib/src/client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_store.dart';

class UpupaClient {
  final String baseUrl;

  final AuthStore authStore;

  final http.Client _httpClient;

  UpupaClient(this.baseUrl, {AuthStore? authStore, http.Client? httpClient})
    : authStore = authStore ?? AuthStore(),
      _httpClient = httpClient ?? http.Client();

  Map<String, String> buildHeaders({Map<String, String>? customHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?customHeaders,
    };

    if (authStore.isValid && authStore.token != null) {
      headers['Authorization'] = 'Bearer ${authStore.token}';
    }

    return headers;
  }

  Future<http.Response> sendGet(
    String path, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    return await _httpClient.get(
      url,
      headers: buildHeaders(customHeaders: headers),
    );
  }

  Future<http.Response> sendPost(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    return await _httpClient.post(
      url,
      headers: buildHeaders(customHeaders: headers),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  void dispose() {
    _httpClient.close();
  }
}
