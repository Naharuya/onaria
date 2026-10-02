import 'package:shared_preferences/shared_preferences.dart';

class MemberRegistrationStore {
  MemberRegistrationStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const memberIdKey = 'onaria.member.id.v1';
  final SharedPreferencesAsync _preferences;

  Future<void> saveMemberId(int memberId) async {
    if (memberId < 1) throw ArgumentError.value(memberId, 'memberId');
    await _preferences.setInt(memberIdKey, memberId);
  }

  Future<int?> loadMemberId() => _preferences.getInt(memberIdKey);
  Future<void> clear() => _preferences.remove(memberIdKey);
}
