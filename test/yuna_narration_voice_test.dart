import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/verse_narration.dart';

void main() {
  test('selects installed Korean Yuna instead of another higher quality voice',
      () {
    expect(
        yunaNarrationVoice([
          {'name': 'Other', 'locale': 'ko-KR', 'quality': 'very high'},
          {
            'name': 'Yuna',
            'locale': 'ko_KR',
            'quality': 'high',
            'identifier': 'com.apple.voice.enhanced.ko-KR.Yuna'
          },
        ])?['name'],
        'Yuna');
  });

  test('does not select unavailable, network-only or wrong-language Yuna', () {
    expect(
        yunaNarrationVoice([
          {'name': 'Yuna', 'locale': 'en-US'},
          {'name': 'Yuna', 'locale': 'ko-KR', 'network_required': true},
          {'name': 'Yuna', 'locale': 'ko-KR', 'features': 'notInstalled'},
        ]),
        isNull);
  });

  test('prefers enhanced Yuna when both qualities are installed', () {
    expect(
        yunaNarrationVoice([
          {
            'name': 'Yuna',
            'locale': 'ko-KR',
            'quality': 'default',
            'identifier': 'com.apple.voice.compact.ko-KR.Yuna'
          },
          {
            'name': 'Yuna',
            'locale': 'ko-KR',
            'quality': 'enhanced',
            'identifier': 'com.apple.voice.enhanced.ko-KR.Yuna'
          },
        ])?['identifier'],
        contains('.enhanced.'));
    expect(yunaNarrationVoice(1), isNull);
  });
}
