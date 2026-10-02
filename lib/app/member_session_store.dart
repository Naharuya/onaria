class MemberSessionStore {
  MemberSessionStore._();
  static final MemberSessionStore instance = MemberSessionStore._();

  String? _token;
  DateTime? _expiresAt;

  bool get hasActiveSession => token != null;
  String? get token {
    final expiresAt = _expiresAt;
    if (_token == null ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now().toUtc())) {
      clear();
      return null;
    }
    return _token;
  }

  void set({required String token, required int expiresInSeconds}) {
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token) ||
        expiresInSeconds < 60 ||
        expiresInSeconds > 86400) {
      throw const FormatException('Invalid member session');
    }
    _token = token;
    _expiresAt =
        DateTime.now().toUtc().add(Duration(seconds: expiresInSeconds));
  }

  void clear() {
    _token = null;
    _expiresAt = null;
  }
}
