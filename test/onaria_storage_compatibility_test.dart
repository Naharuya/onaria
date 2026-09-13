import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/mind_card_store.dart';
import 'package:onaria/engagement/engagement_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/engagement_fakes.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test(
      'ONARIA reads existing cards and conversation summaries without migration',
      () async {
    final preferences = SharedPreferencesAsync();
    final record = jsonEncode({
      'id': 'existing-card',
      'createdAt': '2026-09-13T00:00:00.000',
      'title': '저장된 마음카드',
      'dateLabel': '2026-09-13',
      'emotion': '평온',
      'intensity': 3,
      'verseReference': 'fixture',
      'verseText': '기존 기록',
      'reflectionQuestion': '오늘의 마음',
      'action': '휴식',
      'closingMessage': '마무리',
      'memorySummary': '기존 대화 요약',
    });
    await preferences.setStringList('soul_bible.mind_cards.v1', [record]);
    final cards = await MindCardStore(preferences: preferences).getAll();
    expect(cards.single.id, 'existing-card');
    expect(cards.single.memorySummary, '기존 대화 요약');
    expect(
        await preferences.getStringList('soul_bible.mind_cards.v1'), [record]);
  });

  test('ONARIA restores existing saved engagement records', () async {
    final storage = MemoryEngagementStorage();
    storage.values['soul_bible.engagement.v1'] = jsonEncode({
      'savedVerseIds': ['verse_1']
    });
    final controller = testEngagement(storage: storage, clock: DateTime.now);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.ready, isTrue);
    expect(controller.savedVerseIds, {'verse_1'});
    expect(EngagementController.storageKey, 'soul_bible.engagement.v1');
  });
}
