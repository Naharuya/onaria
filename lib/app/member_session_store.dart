import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class MemberSessionPersistence {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class _SecureMemberSessionPersistence implements MemberSessionPersistence {
  const _SecureMemberSessionPersistence();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemberSessionStore {
  MemberSessionStore._({MemberSessionPersistence? persistence})
      : _persistence = persistence ?? const _SecureMemberSessionPersistence();

  static final MemberSessionStore instance = MemberSessionStore._();

  static const _tokenKey = 'onaria.member_session.token.v1';
  static const _expiresAtKey = 'onaria.member_session.expires_at.v1';

  final MemberSessionPersistence _persistence;
  String? _token;
  DateTime? _expiresAt;

  static MemberSessionStore forTesting(MemberSessionPersistence persistence) =>
      MemberSessionStore._(persistence: persistence);

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

  Future<void> restore() async {
    try {
      final values = await Future.wait([
        _persistence.read(_tokenKey),
        _persistence.read(_expiresAtKey),
      ]);
      final storedToken = values[0];
      final expiresAt = DateTime.tryParse(values[1] ?? '')?.toUtc();
      if (!_validToken(storedToken) ||
          expiresAt == null ||
          !expiresAt.isAfter(DateTime.now().toUtc())) {
        _token = null;
        _expiresAt = null;
        await _deletePersisted();
        return;
      }
      _token = storedToken;
      _expiresAt = expiresAt;
    } catch (_) {
      // Secure storage problems must not prevent app startup or create a
      // partially authenticated state.
      _token = null;
      _expiresAt = null;
    }
  }

  void set({required String token, required int expiresInSeconds}) {
    if (!_validToken(token) ||
        expiresInSeconds < 60 ||
        expiresInSeconds > 86400) {
      throw const FormatException('Invalid member session');
    }
    _token = token;
    _expiresAt =
        DateTime.now().toUtc().add(Duration(seconds: expiresInSeconds));
    unawaited(_persist(token, _expiresAt!));
  }

  void clear() {
    _token = null;
    _expiresAt = null;
    unawaited(_deletePersisted());
  }

  Future<void> _persist(String token, DateTime expiresAt) async {
    try {
      await _persistence.write(_tokenKey, token);
      await _persistence.write(_expiresAtKey, expiresAt.toIso8601String());
    } catch (_) {
      // The in-memory session remains usable for this app run. A future login
      // can retry persistence without weakening server-side authentication.
    }
  }

  Future<void> _deletePersisted() async {
    try {
      await Future.wait([
        _persistence.delete(_tokenKey),
        _persistence.delete(_expiresAtKey),
      ]);
    } catch (_) {
      // Best effort. Expiry is still enforced in memory and by the server.
    }
  }

  static bool _validToken(String? token) =>
      token != null && RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token);
}
