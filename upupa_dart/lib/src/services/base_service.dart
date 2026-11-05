// upupa_dart/lib/src/services/base_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../client.dart';
import '../exceptions.dart';

abstract class BaseService {
  final UpupaClient client;

  BaseService(this.client);

  dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return response.body;
      }
    }

    dynamic errorResponse;
    try {
      errorResponse = jsonDecode(response.body);
    } catch (_) {
      errorResponse = response.body;
    }

    String message = 'Request failed with status code ${response.statusCode}';
    if (errorResponse is Map && errorResponse.containsKey('message')) {
      message = errorResponse['message'];
    }

    switch (response.statusCode) {
      case 401:
        throw UpupaUnauthorizedException(
          message: message,
          response: errorResponse,
        );
      case 403:
        throw UpupaForbiddenException(
          message: message,
          response: errorResponse,
        );
      case 404:
        throw UpupaNotFoundException(message: message, response: errorResponse);
      case 500:
      default:
        if (response.statusCode >= 500) {
          throw UpupaServerException(
            message: message,
            statusCode: response.statusCode,
            response: errorResponse,
          );
        }
        throw UpupaException(
          message: message,
          statusCode: response.statusCode,
          response: errorResponse,
        );
    }
  }
}
