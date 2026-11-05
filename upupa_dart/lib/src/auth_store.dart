// upupa_dart/lib/src/auth_store.dart
class AuthStore {
  String? _token;
  Map<String, dynamic>? _record;

  AuthStore({String? token, Map<String, dynamic>? record})
    : _token = token,
      _record = record;

  String? get token => _token;

  Map<String, dynamic>? get record => _record;

  bool get isValid => _token != null && _token!.isNotEmpty;

  void save(String newToken, Map<String, dynamic>? newRecord) {
    _token = newToken;
    _record = newRecord;
  }

  void clear() {
    _token = null;
    _record = null;
  }
}
