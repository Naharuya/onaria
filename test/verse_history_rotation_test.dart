import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/verse_history.dart';
import 'package:onaria/onaria.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

BibleVerse fixture(String id) => BibleVerse(
      id: id,
      book: 'TEST_DATA_ONLY',
      chapter: 1,
      verseStart: 1,
      verseEnd: null,
      reference: 'TEST_DATA_ONLY',
      translation: 'TEST_DATA_ONLY',
      text: 'TEST_DATA_ONLY',
      englishText: '',
      emotions: const [EmotionType.anxiety],
      tags: const ['TEST_DATA_ONLY'],
      reflectionQuestion: '',
    );
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });
  test(
      'fallback rotates unseen catalog entries and then the least recent entry',
      () async {
    final candidates = [
      fixture('test-a'),
      fixture('test-b'),
      fixture('test-c')
    ];
    final history = VerseHistory();
    final selected = <String>[];
    for (var i = 0; i < 4; i++) {
      selected.add((await history.choose(candidates))!.id);
    }
    expect(selected, ['test-a', 'test-b', 'test-c', 'test-a']);
    expect(await history.choose([]), isNull);
  });
}
