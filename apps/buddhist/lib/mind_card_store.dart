import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// References only: quotation text and user conversation never enter storage.
class MindCardReference {
  const MindCardReference(this.scriptureId, this.savedAt);
  final String scriptureId;
  final DateTime? savedAt;
}

class MindCardStore {
  MindCardStore(this.preferences,
      {DateTime Function()? clock,
      Future<bool> Function(String, String)? writer})
      : _clock = clock ?? DateTime.now,
        _writer = writer ?? preferences.setString {
    _load();
  }
  static const legacyKey = 'onaria.buddhist.test_only.cards.v1';
  static const storageKey = 'onaria.buddhist.test_only.cards.v2';
  final SharedPreferences preferences;
  final DateTime Function() _clock;
  final Future<bool> Function(String, String) _writer;
  final List<MindCardReference> _records = [];
  bool _busy = false;
  bool loadFailed = false;
  List<MindCardReference> get records => List.unmodifiable(_records);

  void _load() {
    try {
      if (!preferences.containsKey(storageKey)) {
        for (final id in (preferences.getStringList(legacyKey) ?? []).toSet()) {
          _records.add(MindCardReference(id, null));
        }
        return;
      }
      final value = jsonDecode(preferences.getString(storageKey)!);
      if (value is! Map ||
          value.length != 2 ||
          value['version'] != 2 ||
          value['cards'] is! List) {
        throw const FormatException();
      }
      for (final row in value['cards'] as List) {
        if (row is! Map ||
            row.length != 2 ||
            row['scriptureId'] is! String ||
            !row.containsKey('savedAt')) {
          throw const FormatException();
        }
        final rawDate = row['savedAt'];
        final date = rawDate == null ? null : DateTime.parse(rawDate as String);
        if (date != null && date.toUtc().toIso8601String() != rawDate) {
          throw const FormatException();
        }
        final id = row['scriptureId'] as String;
        if (_records.any((r) => r.scriptureId == id)) {
          throw const FormatException();
        }
        _records.add(MindCardReference(id, date));
      }
    } catch (_) {
      _records.clear();
      loadFailed = true;
    }
  }

  Future<void> save(String scriptureId) async {
    if (loadFailed) throw StateError('STORAGE_REVIEW_REQUIRED');
    if (_busy) throw StateError('SAVE_IN_PROGRESS');
    if (_records.any((r) => r.scriptureId == scriptureId)) return;
    _busy = true;
    try {
      final updated = [
        MindCardReference(scriptureId, _clock().toUtc()),
        ..._records
      ];
      final payload = jsonEncode({
        'version': 2,
        'cards': [
          for (final row in updated)
            {
              'scriptureId': row.scriptureId,
              'savedAt': row.savedAt?.toUtc().toIso8601String(),
            }
        ]
      });
      try {
        if (!await _writer(storageKey, payload)) {
          throw StateError('SAVE_FAILED');
        }
      } catch (_) {
        // SharedPreferences may update its cache before a failed platform write.
        try {
          await preferences.reload();
        } catch (_) {/* keep original error */}
        rethrow;
      }
      _records
        ..clear()
        ..addAll(updated);
    } finally {
      _busy = false;
    }
  }
}
