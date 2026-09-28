import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/src/conversation/conversation_models.dart' as legacy;
import 'package:onaria_core/onaria_core.dart';

void main() {
  test(
      'Christian emotion names, labels, fallback and import identity remain compatible',
      () {
    const labels = {
      'anxiety': '불안',
      'loneliness': '외로움',
      'exhaustion': '지침',
      'anger': '분노',
      'sadness': '슬픔',
      'complexity': '복잡함',
      'gratitude': '감사',
      'joy': '기쁨',
      'fear': '공포',
      'disgust': '혐오',
      'surprise': '놀람',
      'happiness': '행복',
      'anticipation': '기대',
      'admiration': '감탄',
      'overwhelmed': '벅찬',
      'jealousy': '질투',
    };
    expect(
        {for (final emotion in EmotionType.values) emotion.name: emotion.label},
        labels);
    for (final emotion in EmotionType.values) {
      expect(identical(legacy.EmotionType.fromWire(emotion.name), emotion),
          isTrue);
      expect(EmotionType.fromWire(emotion.label), emotion);
    }
    expect(legacy.EmotionType.fromWire('unknown'), EmotionType.happiness);
    expect(EmotionType.overwhelmed.naturalFeelingPhrase, '벅찬 마음');
    final legacySession = legacy.ConversationSession(
        sessionId: 'synthetic',
        selectedEmotion: EmotionType.anxiety,
        emotionIntensity: 7);
    expect(legacySession.toJson()['selectedEmotion'], '불안');
    expect(legacySession.toJson()['emotionIntensity'], 7);
    expect(legacy.ConversationStage.verseOffer.wireName, 'verse_offer');
  });

  test('Check-in validates intensity outside UI and normalizes optional input',
      () {
    for (final value in [-1, 0, 11, 999]) {
      expect(() => CheckInInput(emotion: EmotionType.anxiety, intensity: value),
          throwsRangeError);
    }
    for (final value in [1, 10]) {
      expect(CheckInInput(emotion: EmotionType.joy, intensity: value).intensity,
          value);
    }
    expect(
        CheckInInput(
                emotion: EmotionType.joy, intensity: 5, customEmotion: ' \n ')
            .customEmotion,
        isNull);
    expect(
        CheckInInput(
                emotion: EmotionType.joy,
                intensity: 5,
                customEmotion: '  마음이 복잡해요  ')
            .customEmotion,
        '마음이 복잡해요');
    expect(
        () => CheckInInput(
            emotion: EmotionType.joy, intensity: 5, customEmotion: '가' * 2001),
        throwsArgumentError);
    expect(
        CheckInInput(
                emotion: EmotionType.joy,
                intensity: 5,
                customEmotion: '가' * 2000)
            .customEmotion!
            .length,
        2000);
  });
}
