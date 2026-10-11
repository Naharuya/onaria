import 'package:shared_preferences/shared_preferences.dart';

/// Only a confirmed server deletion enables local cleanup. A failed or lost
/// server response never starts deletion. Pending cleanup survives app restart.
class MemberRecordCleanup {
  MemberRecordCleanup({SharedPreferencesAsync? preferences})
      : preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync preferences;
  static const _pendingPrefix = 'onaria.records.cleanup_pending.v1.';
  static const _familyKey = 'onaria.records.cleanup_confirmed_owners.v1';

  Future<void> markServerDeletedMany(List<int> memberIds) async {
    if (memberIds.isEmpty || memberIds.any((id) => id < 1))
      throw ArgumentError('Invalid member family');
    final existing = await preferences.getStringList(_familyKey) ?? [];
    await preferences.setStringList(_familyKey,
        {...existing, ...memberIds.map((id) => id.toString())}.toList());
  }

  Future<void> markServerDeleted(int memberId) async {
    if (memberId < 1) throw ArgumentError('Invalid member');
    await preferences.setBool('$_pendingPrefix$memberId', true);
  }

  Future<bool> retry(int memberId) async {
    if (memberId < 1) return false;
    try {
      final family = await preferences.getStringList(_familyKey) ?? [];
      if (!family.contains(memberId.toString()) &&
          await preferences.getBool('$_pendingPrefix$memberId') != true)
        return false;
      final prefix = 'onaria.records.v2.member.$memberId.';
      final keys = await preferences.getKeys();
      for (final key in keys.where((key) => key.startsWith(prefix))) {
        await preferences.remove(key);
      }
      if ((await preferences.getKeys()).any((key) => key.startsWith(prefix)))
        return false;
      final remaining = (await preferences.getStringList(_familyKey) ?? [])
          .where((id) => id != memberId.toString())
          .toList();
      await preferences.setStringList(_familyKey, remaining);
      await preferences.remove('$_pendingPrefix$memberId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> retryConfirmed() async {
    final keys = await preferences.getKeys();
    final ids = <int>{
      for (final raw in await preferences.getStringList(_familyKey) ?? [])
        if (int.tryParse(raw) != null) int.parse(raw),
      for (final key in keys.where((key) => key.startsWith(_pendingPrefix)))
        if (int.tryParse(key.substring(_pendingPrefix.length)) != null)
          int.parse(key.substring(_pendingPrefix.length)),
    };
    for (final id in ids) {
      await retry(id);
    }
  }
}
