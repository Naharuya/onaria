import 'dart:async';
import 'member_record_scope.dart';
import 'package:flutter/foundation.dart';

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

class MemberSessionStore extends ChangeNotifier {
  MemberSessionStore._({MemberSessionPersistence? persistence})
      : _persistence = persistence ?? const _SecureMemberSessionPersistence();

  static final MemberSessionStore instance = MemberSessionStore._();

  static const _tokenKey = 'onaria.member_session.token.v1';
  static const _expiresAtKey = 'onaria.member_session.expires_at.v1';

  final MemberSessionPersistence _persistence;
  String? _token;
  DateTime? _expiresAt;
  int _generation = 0;
  Future<void>? _pendingPersistence;
  bool _restorationFailed = false;
  bool _disposed = false;
  bool _persistenceFailed = false;
  bool _cleanupFailed = false;
  bool get persistenceFailed => _persistenceFailed;
  bool get cleanupFailed => _cleanupFailed;
  Future<bool> flush() async {
    await _pendingPersistence;
    return !_persistenceFailed && !_cleanupFailed;
  }

  DateTime? get expiresAt => _expiresAt;
  bool get restorationFailed => _restorationFailed;

  static MemberSessionStore forTesting(MemberSessionPersistence persistence) =>
      MemberSessionStore._(persistence: persistence);

  bool get hasActiveSession => token != null;

  String? get token {
    final expiresAt = _expiresAt;
    if (_token == null ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now().toUtc())) {
      return null;
    }
    return _token;
  }

  Future<void> restore() async {
    final generation = ++_generation;
    _restorationFailed = false;
    try {
      await _pendingPersistence;
      final values = await Future.wait([
        _persistence.read(_tokenKey),
        _persistence.read(_expiresAtKey),
      ]);
      if (generation != _generation) return;
      final storedToken = values[0];
      final expiresAt = DateTime.tryParse(values[1] ?? '')?.toUtc();
      if (!_validToken(storedToken) ||
          expiresAt == null ||
          !expiresAt.isAfter(DateTime.now().toUtc())) {
        if (identical(this, instance)) MemberRecordScope.instance.signedOut();
        _token = null;
        _expiresAt = null;
        _enqueue(_deletePersisted);
        if (!_disposed) notifyListeners();
        return;
      }
      if (identical(this, instance)) MemberRecordScope.instance.lock();
      _token = storedToken;
      _expiresAt = expiresAt;
      if (!_disposed) notifyListeners();
    } catch (_) {
      // Secure storage problems must not prevent app startup or create a
      // partially authenticated state.
      if (generation == _generation) {
        _restorationFailed = true;
        if (identical(this, instance)) MemberRecordScope.instance.lock();
        _token = null;
        _expiresAt = null;
        if (!_disposed) notifyListeners();
      }
    }
  }

  void set({required String token, required int expiresInSeconds}) {
    if (!_validToken(token) ||
        expiresInSeconds < 60 ||
        expiresInSeconds > 90 * 24 * 60 * 60) {
      throw const FormatException('Invalid member session');
    }
    if (identical(this, instance)) MemberRecordScope.instance.lock();
    _token = token;
    _restorationFailed = false;
    _generation++;
    _expiresAt =
        DateTime.now().toUtc().add(Duration(seconds: expiresInSeconds));
    final expiresAt = _expiresAt!;
    _enqueue(() => _persist(token, expiresAt));
    if (!_disposed) notifyListeners();
  }

  void clear() {
    final hadSession = _token != null || _restorationFailed;
    if (identical(this, instance)) MemberRecordScope.instance.signedOut();
    _generation++;
    _restorationFailed = false;
    _token = null;
    _expiresAt = null;
    _enqueue(_deletePersisted);
    if (hadSession) if (!_disposed) notifyListeners();
  }

  void _enqueue(Future<void> Function() operation) {
    final previous = _pendingPersistence;
    final next =
        previous == null ? operation() : previous.then((_) => operation());
    _pendingPersistence = next;
    unawaited(next.then((_) {
      if (identical(_pendingPersistence, next)) _pendingPersistence = null;
    }));
  }

  Future<void> _persist(String token, DateTime expiresAt) async {
    try {
      await _persistence.write(_tokenKey, token);
      await _persistence.write(_expiresAtKey, expiresAt.toIso8601String());
      _persistenceFailed = false;
    } catch (_) {
      _persistenceFailed = true;
      if (!_disposed) notifyListeners();
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
      _cleanupFailed = false;
      _persistenceFailed = false;
    } catch (_) {
      _cleanupFailed = true;
      if (!_disposed) notifyListeners();
      // Best effort. Expiry is still enforced in memory and by the server.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static bool _validToken(String? token) =>
      token != null && RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token);
}
