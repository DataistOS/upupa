// upupa_dart/lib/src/auth_store.dart
class AuthStore {
  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _record;

  AuthStore({String? token, String? refreshToken, Map<String, dynamic>? record})
    : _token = token,
      _refreshToken = refreshToken,
      _record = record;

  String? get token => _token;

  String? get refreshToken => _refreshToken;

  Map<String, dynamic>? get record => _record;

  bool get isValid => _token != null && _token!.isNotEmpty;

  void save(String newToken, [dynamic arg1, Map<String, dynamic>? arg2]) {
    _token = newToken;
    if (arg1 is String?) {
      _refreshToken = arg1;
      _record = arg2;
    } else if (arg1 is Map<String, dynamic>?) {
      _refreshToken = null;
      _record = arg1;
    }
  }

  void clear() {
    _token = null;
    _refreshToken = null;
    _record = null;
  }
}
