import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/care_personalization.dart';
import '../lib/common_emotion_examples.dart';
import '../lib/all_emotion_examples.dart';

void main() {
  test(
      'five factors, explicit need, negation, correction, repetition and clear',
      () {
    final c = CarePersonalization(emotion: '불안', intensity: 8);
    expect(c.question(0), contains('짧게'));
    c.accept('업무가 겹쳐요', question: c.question(0));
    expect(c.question(1), contains('겹친 일'));
    c.accept('쉬기 싫고 먼저 정리하고 싶어요', question: c.question(1));
    expect(c.desiredHelp, 'order');
    expect(c.question(2), contains('한 가지'));
    c.accept('정리는 원치 않아요. 위로가 필요해요', question: c.question(2));
    expect(c.desiredHelp, 'connection');
    final next = c.question(3);
    c.accept('사실은 가족과 서운한 일이 있었어요', question: next);
    expect(c.topic, 'relationship');
    expect(c.question(4), isNot(next));
    expect(c.toJson()['alreadyAnswered'], hasLength(4));
    final mixed = CarePersonalization(emotion: '벅찬', intensity: 7);
    mixed.accept('저는 반갑고 기쁜 느낌에 가까워요.',
        question: '지금은 반가운 느낌과 버거운 느낌 중 어느 쪽에 더 가까운가요?');
    expect(mixed.situation, isEmpty);
    expect(mixed.question(1), contains('어떤 일'));
    mixed.accept('오늘 좋은 소식을 들었어요', question: mixed.question(1));
    expect(mixed.situation, '오늘 좋은 소식을 들었어요');
    final custom = CarePersonalization(emotion: '설레지만 걱정돼요', intensity: 5);
    custom.accept('쉬고 싶어요');
    final asked = custom.question(1);
    custom.accept('아직 쉬고 싶어요', question: '직접 적은 마음을 살펴볼게요. $asked');
    expect(custom.question(2), isNot(asked));

    c.clear();
    expect(c.answers, isEmpty);
    expect(c.desiredHelp, 'unspecified');
  });
  test('facts are not automatically desired help; positive high intensity', () {
    final c = CarePersonalization(emotion: '기쁨', intensity: 9);
    c.accept('친구에게 연락이 왔어요');
    expect(c.desiredHelp, 'unspecified');
    expect(c.lowBurden, isFalse);
    expect(CarePersonalization(emotion: '기뻐요', intensity: 9).lowBurden, isFalse);
    expect(CarePersonalization(emotion: '평온해요', intensity: 9).lowBurden, isFalse);
    final d = CarePersonalization(emotion: '슬픔', intensity: 3);
    d.accept('쉬고 싶어요');
    d.accept('휴식 말고');
    expect(d.desiredHelp, 'unspecified');
    for (var i = 0; i < 9; i++) {
      d.accept('답변');
    }
    expect(d.answers, hasLength(5));
  });
  test('every source example survives in shared bank', () {
    final inventory = jsonDecode(
        File('docs/personalization-example-inventory.json')
            .readAsStringSync()) as Map;
    expect(commonEmotionExamples, hasLength(16));
    for (final source in inventory['provenance'] as List) {
      expect(
          commonEmotionExamples[source['emotion']], contains(source['text']));
    }
    for (final source in inventory['conversationProvenance'] as List) {
      expect(commonConversationExamples, contains(source['text']));
    }
    expect(commonConversationExamples.toSet(),
        hasLength(commonConversationExamples.length));
  });
  testWidgets('full examples are accessible and selected without deletion',
      (tester) async {
    String? selected;
    final examples = commonEmotionExamples['불안']!;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AllEmotionExamples(
                examples: examples, onSelected: (value) => selected = value))));
    await tester.tap(find.byKey(const ValueKey('all-emotion-examples')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(examples.last), 200);
    await tester.tap(find.text(examples.last));
    await tester.pumpAndSettle();
    expect(selected, examples.last);
  });
}
