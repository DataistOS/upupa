// upupa_dart/lib/src/exceptions.dart
class UpupaException implements Exception {
  final String message;

  final int? statusCode;

  final dynamic response;

  UpupaException({required this.message, this.statusCode, this.response});

  @override
  String toString() {
    if (statusCode != null) {
      return 'UpupaException: [$statusCode] $message';
    }
    return 'UpupaException: $message';
  }
}

class UpupaUnauthorizedException extends UpupaException {
  UpupaUnauthorizedException({
    String message = 'Unauthorized access or invalid token.',
    int? statusCode = 401,
    dynamic response,
  }) : super(message: message, statusCode: statusCode, response: response);
}

class UpupaForbiddenException extends UpupaException {
  UpupaForbiddenException({
    String message = 'You do not have permission to access this resource.',
    int? statusCode = 403,
    dynamic response,
  }) : super(message: message, statusCode: statusCode, response: response);
}

class UpupaNotFoundException extends UpupaException {
  UpupaNotFoundException({
    String message = 'The requested resource was not found.',
    int? statusCode = 404,
    dynamic response,
  }) : super(message: message, statusCode: statusCode, response: response);
}

class UpupaServerException extends UpupaException {
  UpupaServerException({
    String message = 'Internal server error occurred.',
    int? statusCode = 500,
    dynamic response,
  }) : super(message: message, statusCode: statusCode, response: response);
}
