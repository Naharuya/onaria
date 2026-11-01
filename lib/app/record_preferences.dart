import 'package:shared_preferences/shared_preferences.dart';
import 'member_record_scope.dart';

/// Serializes record mutations across stores. Deletion drains writes already
/// handed to the OS and rejects old generations before removing only one scope.
class RecordPreferences extends SharedPreferencesAsync {
  RecordPreferences({SharedPreferencesAsync? preferences})
      : _delegate = preferences is RecordPreferences
            ? preferences._delegate
            : preferences ?? SharedPreferencesAsync(),
        _access = MemberRecordScope.instance.capture();
  final SharedPreferencesAsync _delegate;
  final RecordAccess _access;
  static Future<void>? _tail;
  Future<void> _write(Future<void> Function() action) {
    Future<void> checked() {
      try {
        _access.requireCurrent();
        return action();
      } catch (error, stack) {
        return Future<void>.error(error, stack);
      }
    }

    final previous = _tail;
    final result =
        previous == null ? checked() : previous.then((_) => checked());
    late final Future<void> settled;
    void release() {
      if (identical(_tail, settled)) _tail = null;
    }

    settled = result.then<void>((_) => release(),
        onError: (Object _, StackTrace __) => release());
    _tail = settled;
    return result;
  }

  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) =>
      _delegate.getKeys(allowList: allowList);
  @override
  Future<Map<String, Object?>> getAll({Set<String>? allowList}) =>
      _delegate.getAll(allowList: allowList);
  @override
  Future<String?> getString(String key) => _delegate.getString(key);
  @override
  Future<List<String>?> getStringList(String key) =>
      _delegate.getStringList(key);
  @override
  Future<bool?> getBool(String key) => _delegate.getBool(key);
  @override
  Future<int?> getInt(String key) => _delegate.getInt(key);
  @override
  Future<double?> getDouble(String key) => _delegate.getDouble(key);
  @override
  Future<void> setString(String key, String value) =>
      _write(() => _delegate.setString(key, value));
  @override
  Future<void> setStringList(String key, List<String> value) =>
      _write(() => _delegate.setStringList(key, List.of(value)));
  @override
  Future<void> setBool(String key, bool value) =>
      _write(() => _delegate.setBool(key, value));
  @override
  Future<void> setInt(String key, int value) =>
      _write(() => _delegate.setInt(key, value));
  @override
  Future<void> setDouble(String key, double value) =>
      _write(() => _delegate.setDouble(key, value));
  @override
  Future<void> remove(String key) => _write(() => _delegate.remove(key));
  @override
  Future<void> clear({Set<String>? allowList}) {
    if (allowList == null) throw ArgumentError('Explicit keys required');
    return _write(() => _delegate.clear(allowList: allowList));
  }

  static Future<void> deleteCurrent(
      {SharedPreferencesAsync? preferences}) async {
    final scope = MemberRecordScope.instance;
    final access = scope.capture();
    access.requireCurrent();
    final prefix = access.key('');
    final generation = scope.beginRecordDeletion();
    final raw = preferences ?? SharedPreferencesAsync();
    try {
      await _tail;
      scope.requireDeletion(generation);
      final keys = await raw.getKeys();
      for (final key in keys.where((key) => key.startsWith(prefix))) {
        scope.requireDeletion(generation);
        await raw.remove(key);
      }
      scope.requireDeletion(generation);
      final remaining = await raw.getKeys();
      scope.requireDeletion(generation);
      if (remaining.any((key) => key.startsWith(prefix))) {
        throw StateError('Record deletion verification failed');
      }
    } finally {
      scope.finishRecordDeletion(generation);
    }
  }
}
