import 'package:shared_preferences/shared_preferences.dart';
import '../app/member_record_scope.dart';

abstract interface class EngagementStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class PreferencesEngagementStorage implements EngagementStorage {
  PreferencesEngagementStorage({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  final RecordAccess _access = MemberRecordScope.instance.capture();
  @override
  Future<String?> read(String key) async {
    _access.requireCurrent();
    final value = await _preferences.getString(_access.key(key));
    _access.requireCurrent();
    return value;
  }

  @override
  Future<void> write(String key, String value) {
    _access.requireCurrent();
    return _preferences.setString(_access.key(key), value);
  }
}
