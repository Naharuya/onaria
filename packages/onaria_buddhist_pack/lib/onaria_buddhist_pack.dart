import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class MockScripture {
  MockScripture._(Map<String, dynamic> value)
      : _data = Map.unmodifiable(value.map((key, value) =>
            MapEntry(key, value is List ? List.unmodifiable(value) : value)));

  final Map<String, dynamic> _data;
  String get id => _data['id'] as String;
  String get title => _data['title'] as String;
  String get text => _data['text'] as String;
  String get source => _data['source'] as String;
  String get license => _data['license'] as String;
  String get copyrightStatus => _data['copyright_status'] as String;
  List<String> get themes => List<String>.unmodifiable(_data['themes'] as List);
  List<String> get emotions =>
      List<String>.unmodifiable(_data['emotion_tags'] as List);
  Map<String, dynamic> get metadata => _data;
}

class BuddhistScriptureProvider {
  BuddhistScriptureProvider._(this._records);
  final List<MockScripture> _records;

  static Future<BuddhistScriptureProvider> load() async {
    final raw = jsonDecode(await rootBundle.loadString(
        'packages/onaria_buddhist_pack/assets/mock_scriptures.json')) as List;
    final records = raw.map((item) {
      final data = Map<String, dynamic>.from(item as Map);
      if (data['copyright_status'] != 'TEST_DATA_ONLY' ||
          data['religion'] != 'buddhist' ||
          !(data['text'] as String).startsWith('[TEST_DATA_ONLY]') ||
          data['translator'] != null ||
          data['chapter'] != null ||
          data['section'] != null) {
        throw StateError('UNSUPPORTED_SCRIPTURE');
      }
      return MockScripture._(data);
    }).toList(growable: false);
    return BuddhistScriptureProvider._(List.unmodifiable(records));
  }

  MockScripture? getById(String id) {
    for (final record in _records) {
      if (record.id == id) return record;
    }
    return null;
  }

  List<MockScripture> searchByTheme(String theme) =>
      _records.where((r) => r.themes.contains(theme)).toList(growable: false);
  List<MockScripture> searchByEmotion(String emotion) => _records
      .where((r) => r.emotions.contains(emotion))
      .toList(growable: false);
  List<MockScripture> search(String query) {
    final value = query.trim();
    if (value.isEmpty || value.length > 2000) return const [];
    return _records
        .where((r) => [
              ...r.themes,
              ...r.emotions,
              ...List<String>.from(r.metadata['tags'] as List),
            ].any(value.contains))
        .toList(growable: false);
  }

  String? getSource(String id) => getById(id)?.source;
  String? getLicense(String id) => getById(id)?.license;
  MockScripture? getRandomReflection({Random? random}) => _records.isEmpty
      ? null
      : _records[(random ?? Random()).nextInt(_records.length)];

  void assertCitation(Map<String, dynamic> candidate) {
    final source = getById(candidate['id']?.toString() ?? '');
    // Canonical JSON comparison ignores map insertion order, retains exact values.
    dynamic canonical(dynamic value) {
      if (value is Map) {
        final keys = value.keys.cast<String>().toList()..sort();
        return {for (final key in keys) key: canonical(value[key])};
      }
      if (value is List) return value.map(canonical).toList();
      return value;
    }

    if (source == null ||
        jsonEncode(canonical(source.metadata)) !=
            jsonEncode(canonical(candidate))) {
      throw StateError('UNSUPPORTED_SCRIPTURE');
    }
  }
}
