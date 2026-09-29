import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('launch bible bundle contains KRV only and no NIV text', () {
    final raw = File('assets/data/bible_verses_ko.json').readAsStringSync();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    expect(data['translation'], 'KRV');
    expect(raw.contains('NIV'), isFalse);
    for (final item in data['verses'] as List) {
      final verse = item as Map<String, dynamic>;
      expect(verse['translation'], 'KRV');
      expect(verse['englishText'], '');
    }
  });

  test('app exposes separate content copyright and open-source license entries', () {
    final source = File('lib/features/check_in_page.dart').readAsStringSync();
    expect(source, contains('콘텐츠 및 성경 저작권'));
    expect(source, contains('오픈소스 라이선스'));
  });

  test('legacy NIV text is not exported from mind cards', () {
    final source = File('lib/app/mind_card_store.dart').readAsStringSync();
    expect(source, isNot(contains('English (NIV)')));
  });
}
