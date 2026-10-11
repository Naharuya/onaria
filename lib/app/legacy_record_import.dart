import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'member_record_scope.dart';

/// Explicit, non-destructive copy only. No UI enables this until local ownership
/// verification is available. Legacy records and damaged entries stay intact.
class LegacyRecordImport {
  LegacyRecordImport({SharedPreferencesAsync? preferences})
      : preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync preferences;
  static const listKeys = [
    'soul_bible.mind_cards.v1',
    'onaria.recent_verses.v1'
  ];
  static const stringKeys = [
    'onaria.unsent_draft.v1',
    'soul_bible.engagement.v1',
    'onaria.emotion_card.preset_counts.v1',
    'onaria.emotion_card.custom_keyword_counts.v1'
  ];
  static const claimKey = 'onaria.legacy_records.import_claim.v1';
  static Future<void> _tail = Future.value();

  Future<Map<String, int>> inventory() async {
    final counts = <String, int>{};
    for (final key in listKeys) {
      counts[key] = (await preferences.getStringList(key))?.length ?? 0;
    }
    for (final key in stringKeys) {
      counts[key] = await preferences.getString(key) == null ? 0 : 1;
    }
    return counts;
  }

  Future<void> copyToCurrentMember({required bool deviceOwnershipVerified}) {
    final access = MemberRecordScope.instance.capture();
    final operation = _tail.then((_) => _copy(access, deviceOwnershipVerified));
    _tail = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _copy(RecordAccess access, bool confirmed) async {
    access.requireCurrent();
    if (!confirmed || access.memberId == null)
      throw StateError('Ownership confirmation required');
    final claim = await preferences.getString(claimKey);
    if (claim != null) {
      final owner = jsonDecode(claim);
      if (owner['memberId'] != access.memberId)
        throw StateError('Legacy records claimed by another member');
      if (owner['complete'] == true) return;
    }
    access.requireCurrent();
    // Durable claim makes interrupted imports resumable only for the same owner.
    await preferences.setString(
        claimKey, jsonEncode({'memberId': access.memberId, 'complete': false}));
    for (final key in listKeys) {
      final source = await preferences.getStringList(key);
      if (source == null) continue;
      access.requireCurrent();
      final target = access.key(key);
      final existing = await preferences.getStringList(target);
      if (existing != null && jsonEncode(existing) != jsonEncode(source))
        throw StateError('Existing member records require reviewed merge');
      access.requireCurrent();
      await preferences.setStringList(target, source);
      if (jsonEncode(await preferences.getStringList(target)) !=
          jsonEncode(source)) throw StateError('Import verification failed');
    }
    for (final key in stringKeys) {
      final source = await preferences.getString(key);
      if (source == null) continue;
      access.requireCurrent();
      final target = access.key(key);
      final existing = await preferences.getString(target);
      if (existing != null && existing != source)
        throw StateError('Existing member records require reviewed merge');
      access.requireCurrent();
      await preferences.setString(target, source);
      if (await preferences.getString(target) != source)
        throw StateError('Import verification failed');
    }
    access.requireCurrent();
    await preferences.setString(
        claimKey, jsonEncode({'memberId': access.memberId, 'complete': true}));
  }
}
