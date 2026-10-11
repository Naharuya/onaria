import 'dart:convert';
import 'member_record_scope.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../onaria.dart';

class ConversationDraft {
  const ConversationDraft(
      {required this.text,
      required this.emotion,
      required this.intensity,
      this.customEmotion});
  final String text;
  final EmotionType emotion;
  final int intensity;
  final String? customEmotion;
  static const _key = 'onaria.unsent_draft.v1';
  static String get autoSaveKey {
    final access = MemberRecordScope.instance.capture();
    access.requireCurrent();
    return access.key('onaria.draft_autosave.v1');
  }

  static Future<void>? _pending;
  static Future<void> _serial(Future<void> Function() action) async {
    while (_pending != null) {
      await _pending;
    }
    final completion = Completer<void>();
    _pending = completion.future;
    try {
      await action();
    } finally {
      _pending = null;
      completion.complete();
    }
  }

  Future<void> save() {
    final access = MemberRecordScope.instance.capture();
    return _serial(() {
      access.requireCurrent();
      if (const CrisisDetector().assess(text).isCrisis ||
          const CrisisDetector().assess(customEmotion ?? '').isCrisis) {
        throw StateError('Safety input is not saved as a draft');
      }
      return SharedPreferencesAsync().setString(
          access.key(_key),
          jsonEncode({
            'text': text,
            'emotion': emotion.name,
            'intensity': intensity,
            'customEmotion': customEmotion,
          }));
    });
  }

  static Future<void> delete() {
    final access = MemberRecordScope.instance.capture();
    return _serial(() {
      access.requireCurrent();
      return SharedPreferencesAsync().remove(access.key(_key));
    });
  }

  static Future<ConversationDraft?> load() async {
    final access = MemberRecordScope.instance.capture();
    if (_pending != null) await _pending;
    access.requireCurrent();
    final raw = await SharedPreferencesAsync().getString(access.key(_key));
    access.requireCurrent();
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      return ConversationDraft(
          text: value['text'] as String,
          emotion: EmotionType.fromWire(value['emotion'] as String),
          intensity: (value['intensity'] as int).clamp(1, 10),
          customEmotion: value['customEmotion'] as String?);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
