import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'member_record_scope.dart';
import 'member_session_store.dart';
import 'mind_card_store.dart';
import '../src/api/provider_auth_api_client.dart';

class MergedRecordArchive {
  const MergedRecordArchive(
      {required this.cards,
      required this.draft,
      required this.engagement,
      required this.recentVerseIds,
      required this.presetCounts,
      required this.customCounts,
      required this.unreadableItems});
  final List<MindCardRecord> cards;
  final String? draft;
  final Map<String, dynamic> engagement, presetCounts, customCounts;
  final List<String> recentVerseIds;
  final int unreadableItems;
}

class MergedRecordReader {
  MergedRecordReader(
      {required this.client,
      required this.sessions,
      SharedPreferencesAsync? preferences})
      : preferences = preferences ?? SharedPreferencesAsync();
  final ProviderAuthApiClient client;
  final MemberSessionStore sessions;
  final SharedPreferencesAsync preferences;
  Future<List<MergedRecordArchive>> load() async {
    final token = sessions.token, access = MemberRecordScope.instance.capture();
    access.requireCurrent();
    if (token == null || access.memberId == null)
      throw StateError('Verified account required');
    final account = await client.account(token);
    access.requireCurrent();
    if (sessions.token != token || account.memberId != access.memberId)
      throw StateError('Account changed');
    final owners = account.recordOwnerIds;
    if (!owners.contains(account.memberId) ||
        owners.toSet().length != owners.length ||
        owners.any((id) => id < 1)) {
      throw const FormatException('Invalid owner mapping');
    }
    final archives = <MergedRecordArchive>[];
    for (final owner in owners.where((id) => id != account.memberId)) {
      access.requireCurrent();
      final prefix = 'onaria.records.v2.member.$owner.';
      var unreadable = 0;
      Future<Map<String, dynamic>> map(String key) async {
        try {
          final raw = await preferences.getString(prefix + key);
          if (raw == null) return {};
          final decoded = jsonDecode(raw);
          if (decoded is! Map<String, dynamic>) throw const FormatException();
          return decoded;
        } catch (_) {
          unreadable++;
          return {};
        }
      }

      final cards = <MindCardRecord>[];
      try {
        for (final raw in await preferences
                .getStringList('${prefix}soul_bible.mind_cards.v1') ??
            const <String>[]) {
          try {
            cards.add(MindCardRecord.fromJson(
                Map<String, dynamic>.from(jsonDecode(raw) as Map)));
          } catch (_) {
            unreadable++;
          }
        }
      } catch (_) {
        unreadable++;
      }
      final draft = await map('onaria.unsent_draft.v1');
      final engagement = await map('soul_bible.engagement.v1');
      final presets = await map('onaria.emotion_card.preset_counts.v1');
      final customs = await map('onaria.emotion_card.custom_keyword_counts.v1');
      var recent = <String>[];
      try {
        recent = await preferences
                .getStringList('${prefix}onaria.recent_verses.v1') ??
            [];
      } catch (_) {
        unreadable++;
      }
      access.requireCurrent();
      if (sessions.token != token) throw StateError('Session changed');
      archives.add(MergedRecordArchive(
          cards: List.unmodifiable(cards),
          draft: draft['text'] is String ? draft['text'] as String : null,
          engagement: engagement,
          recentVerseIds: recent,
          presetCounts: presets,
          customCounts: customs,
          unreadableItems: unreadable));
    }
    access.requireCurrent();
    if (sessions.token != token) throw StateError('Session changed');
    return List.unmodifiable(archives);
  }
}
