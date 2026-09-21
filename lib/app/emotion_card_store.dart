import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../src/conversation/conversation_models.dart';

class EmotionCardStats {
  const EmotionCardStats({
    required this.presetCounts,
    required this.customKeywordCounts,
  });

  final Map<String, int> presetCounts;
  final Map<String, int> customKeywordCounts;

  int presetCount(EmotionType emotion) => presetCounts[emotion.name] ?? 0;

  List<MapEntry<String, int>> popularCustomKeywords({
    int minimumCount = 30,
    int limit = 12,
  }) {
    final items = customKeywordCounts.entries
        .where((entry) => entry.value >= minimumCount)
        .toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return items.take(limit).toList(growable: false);
  }
}

class EmotionCardStore {
  EmotionCardStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _presetKey = 'onaria.emotion_card.preset_counts.v1';
  static const _customKey = 'onaria.emotion_card.custom_keyword_counts.v1';
  final SharedPreferencesAsync _preferences;

  static const _stopWords = <String>{
    '그냥', '조금', '너무', '정말', '진짜', '오늘', '지금', '마음', '기분',
    '느낌', '같아', '같아요', '있어요', '없어요', '돼요', '해요', '하고',
    '해서', '하지만', '그리고', '때문에', '뭔가', '약간', '계속', '자꾸',
  };

  Future<EmotionCardStats> load() async => EmotionCardStats(
        presetCounts: await _readMap(_presetKey),
        customKeywordCounts: await _readMap(_customKey),
      );

  Future<void> recordPreset(EmotionType emotion) async {
    final counts = await _readMap(_presetKey);
    counts[emotion.name] = (counts[emotion.name] ?? 0) + 1;
    await _writeMap(_presetKey, counts);
  }

  Future<void> recordCustom(String text) async {
    final keywords = extractKeywords(text);
    if (keywords.isEmpty) return;
    final counts = await _readMap(_customKey);
    for (final keyword in keywords.toSet()) {
      counts[keyword] = (counts[keyword] ?? 0) + 1;
    }
    await _writeMap(_customKey, counts);
  }

  List<String> extractKeywords(String text) {
    final cleaned = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^0-9a-z가-힣\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return const [];

    final result = <String>[];
    for (var token in cleaned.split(' ')) {
      token = token
          .replaceFirst(RegExp(r'(으로|에서|에게|한테|처럼|보다|까지|부터)$'), '')
          .replaceFirst(RegExp(r'(은|는|이|가|을|를|에|도|와|과|랑)$'), '');
      if (token.length < 2 || token.length > 12 || _stopWords.contains(token)) {
        continue;
      }
      result.add(token);
      if (result.length == 5) break;
    }
    return result;
  }

  Future<Map<String, int>> _readMap(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      return decoded.map((key, value) => MapEntry(
            key.toString(),
            value is int ? value : int.tryParse(value.toString()) ?? 0,
          ));
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> _writeMap(String key, Map<String, int> value) =>
      _preferences.setString(key, jsonEncode(value));
}
