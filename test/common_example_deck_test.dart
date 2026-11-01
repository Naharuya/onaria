import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/common_emotion_examples.dart';
import 'package:onaria/personal_keywords.dart';
import 'package:onaria/personal_keyword_panel.dart';

void main() {
  test('all original card and conversation examples remain verbatim', () {
    final source = jsonDecode(
            File('docs/emotion-example-union-20261101.json').readAsStringSync())
        as Map;
    for (final entry in (source['previousByEmotion'] as Map).entries) {
      expect(
          commonEmotionExamples[entry.key], containsAll(entry.value as List));
    }
    expect(commonConversationExamples,
        containsAll(source['previousConversationExamples'] as List));
    expect(commonEmotionExamples.keys, hasLength(16));
  });
  test(
      'card suggestions are scoped and high/low intensity wording is preserved',
      () {
    expect(commonCardExamples('기쁨'), everyElement(isNot(contains('화를 참기'))));
    expect(commonCardExamples('불안', intensity: 2).first, '작은 일이 조금 신경 쓰여요.');
    expect(commonCardExamples('불안', intensity: 9).first,
        '걱정이 커서 지금은 짧게 이야기하고 싶어요.');
  });
  test('five slots refill without selected items across ten selections', () {
    final deck = ConversationExampleDeck();
    final used = <String>{};
    for (var i = 0; i < 10; i++) {
      final values = deck.next(
          question: '어떤 생각이 떠올랐나요?',
          primary: const ['제 마음을 정리하고 싶어요.', '조금 더 생각하고 싶어요.'],
          emotion: '불안');
      expect(values, hasLength(5));
      expect(values.toSet(), hasLength(5));
      expect(values.where(used.contains), isEmpty);
      used.add(values.first);
      deck.select(values.first);
    }
  });
  test(
      'starting deck uses the selected card; fresh conversation resets consumption',
      () {
    final deck = ConversationExampleDeck();
    final values = deck.next(
        question: '어떤 일이 있었나요?',
        primary: commonCardExamples('기쁨'),
        emotion: '기쁨',
        starting: true);
    expect(values, hasLength(5));
    expect(values, everyElement(isIn(commonEmotionExamples['기쁨']!)));
    deck.select(values.first);
    final next = deck.next(
        question: '어떤 일이 있었나요?',
        primary: commonCardExamples('기쁨'),
        emotion: '기쁨',
        starting: true);
    expect(next, hasLength(5));
    expect(next, isNot(contains(values.first)));
    expect(ConversationExampleDeck().wasSelected(values.first), isFalse);
  });
  test(
      'keywords normalize aliases once per manual safe message; promote at three',
      () {
    final learning = PersonalKeywordLearning();
    learning.observe('회사에서 업무가 업무가 많아요.', emotion: '불안', safe: true);
    learning.observe('회사 업무를 이야기해요.', emotion: '불안', safe: true);
    expect(learning.cards, isEmpty);
    learning.observe('업무 때문에 생각이 많아요.', emotion: '불안', safe: true);
    expect(learning.cards, ['업무']);
    expect(learning.examples('불안'), isNotEmpty);
    expect(learning.examples('기쁨'), isEmpty);
    expect(learning.examples('업무'), hasLength(6));
  });
  test('unsafe input and selected suggestions never teach the model', () {
    final learning = PersonalKeywordLearning();
    for (var i = 0; i < 10; i++) {
      learning.observe('회사 업무', emotion: '불안', safe: false);
      learning.observe('회사 업무', emotion: '불안', safe: true, fromExample: true);
    }
    expect(learning.cards, isEmpty);
    expect(
        PersonalKeywordLearning.keywords(
            '홍길동 010-1234-5678 someone@example.com 123456789 우울증'),
        isEmpty);
  });
  test('off, clear and account transition erase keyword-derived suggestions',
      () {
    var current = true;
    final learning = PersonalKeywordLearning(isCurrent: () => current);
    for (var i = 0; i < 3; i++) {
      learning.observe('시험 공부', emotion: '불안', safe: true);
    }
    expect(learning.cards, ['학업']);
    current = false;
    expect(learning.cards, isEmpty);
    current = true;
    expect(learning.cards, isEmpty);
    for (var i = 0; i < 3; i++) {
      learning.observe('회사 업무', emotion: '불안', safe: true);
    }
    learning.setEnabled(false);
    expect(learning.cards, isEmpty);
    learning.setEnabled(true);
    expect(learning.cards, isEmpty);
  });
  testWidgets('promoted topic is selectable and clearing removes its chip',
      (tester) async {
    final learning = PersonalKeywordLearning();
    for (var i = 0; i < 3; i++) {
      learning.observe('회사 업무', emotion: '불안', safe: true);
    }
    String? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: PersonalKeywordPanel(
                    learning: learning,
                    onSelected: (value) => selected = value)))));
    await tester.tap(find.byKey(const ValueKey('personal-topic-업무')));
    expect(selected, '업무');
    await tester.tap(find.text('추가된 주제와 예시 지우기'));
    await tester.pump();
    expect(find.byKey(const ValueKey('personal-topic-업무')), findsNothing);
  });
  test(
      'negation and correction never promote a topic; individual removal stays removed',
      () {
    final learning = PersonalKeywordLearning();
    for (var i = 0; i < 4; i++) {
      learning.observe('업무 이야기는 아니에요.', emotion: '불안', safe: true);
    }
    expect(learning.cards, isEmpty);
    for (var i = 0; i < 3; i++) {
      learning.observe('회사 업무', emotion: '불안', safe: true);
    }
    expect(learning.cards, contains('업무'));
    learning.remove('업무');
    for (var i = 0; i < 5; i++) {
      learning.observe('회사 업무', emotion: '불안', safe: true);
    }
    expect(learning.cards, isEmpty);
  });
}
