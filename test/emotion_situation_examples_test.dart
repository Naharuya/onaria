import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/features/emotion_situation_examples.dart';
import 'package:onaria/features/conversation_question_examples.dart';
import 'package:onaria/src/conversation/conversation_models.dart';
import 'package:onaria/src/safety/crisis_detector.dart';

void main() {
  test('모든 기본 카드에 안전하고 서로 다른 상황 예시 여섯 개 제공', () {
    expect(emotionSituationExamples.keys.toSet(), EmotionType.values.toSet());
    for (final emotion in EmotionType.values) {
      final examples = emotionSituationExamples[emotion]!;
      expect(examples, hasLength(6));
      expect(examples.toSet(), hasLength(6));
      for (final example in examples) {
        expect(const CrisisDetector().assess(example).isCrisis, isFalse);
      }
      expect(
          conversationQuestionExamples('어떤 일이 있었나요?',
              emotion: emotion, situationExamples: examples),
          examples);
    }
  });
  test('서버의 질문별 새 예시는 반영하지만 모르는 선택 질문에 상황 예시를 붙이지 않음', () {
    expect(
        conversationQuestionExamples('어떤 색이 떠오르나요?',
            answerExamples: ['연한 초록색이 떠올라요.']),
        ['연한 초록색이 떠올라요.']);
    expect(
        conversationQuestionExamples('빨강과 파랑 중 어떤 색인가요?',
            emotion: EmotionType.joy,
            situationExamples: emotionSituationExamples[EmotionType.joy]!),
        isEmpty);
  });
}
