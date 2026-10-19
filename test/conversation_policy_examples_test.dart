import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/features/conversation_question_examples.dart';
import 'package:onaria/onaria.dart';

void main() {
  test(
      'jointly authored direct answers take priority over generic choice templates',
      () {
    expect(
        conversationQuestionExamples('위로, 이해 중 무엇이 필요한가요?',
            answerExamples: ['저는 오늘 일을 이해받고 싶어요.']),
        ['저는 오늘 일을 이해받고 싶어요.']);
  });
  test('overwhelmed feeling keeps both pleasant and burdensome example choices',
      () {
    expect(
        conversationQuestionExamples('어떤 마음인가요?',
            emotion: EmotionType.overwhelmed,
            userMessage: '벅차요',
            answerExamples: ['저는 기쁘고 고마워요.', '저는 걱정이 돼요.']),
        ['저는 기쁘고 고마워요.', '저는 걱정이 돼요.']);
  });
}
