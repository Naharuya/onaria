import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/emotion_card_store.dart';
import 'package:onaria/src/conversation/conversation_models.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('frequent custom keyword is promoted after 30 uses', () async {
    final store = EmotionCardStore();
    for (var i = 0; i < 30; i++) {
      await store.recordCustom('회사 스트레스가 너무 커요');
    }
    final stats = await store.load();
    expect(stats.popularCustomKeywords().map((e) => e.key), contains('스트레스'));
    expect(stats.customKeywordCounts['스트레스'], 30);
  });

  test('preset emotion counts can drive card ordering', () async {
    final store = EmotionCardStore();
    await store.recordPreset(EmotionType.joy);
    await store.recordPreset(EmotionType.joy);
    await store.recordPreset(EmotionType.anxiety);
    final stats = await store.load();
    expect(stats.presetCount(EmotionType.joy), 2);
    expect(stats.presetCount(EmotionType.anxiety), 1);
  });
}
