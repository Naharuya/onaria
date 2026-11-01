import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../lib/care_personalization.dart';
import '../lib/src/api/llm_models.dart';
import '../lib/src/conversation/conversation_models.dart';

void main() {
  test(
      'maximum Korean history stays below 16 KiB without changing current input or local state',
      () {
    final c = CarePersonalization(emotion: '불안', intensity: 8);
    for (var i = 0; i < 5; i++) {
      c.accept('업무 ' + ('가' * 1980) + ' 쉬고 싶어요.',
          question: '지금 필요한 도움은 무엇인가요?');
    }
    final current = c.answers.last;
    final session = ConversationSession(
        sessionId: 'budget',
        selectedEmotion: EmotionType.anxiety,
        emotionIntensity: 8,
        summary: '요' * 4000,
        agentMemory: '약' * 4000,
        lastUserMessage: '이' * 2000,
        lastAssistantQuestion: '질' * 1000);
    final request = LlmConversationRequest(
        session: session,
        userMessage: current,
        systemPromptVersion: 'ko-v1',
        personalizationContext: c.toJson(),
        allowedVerseIds:
            List.generate(100, (i) => 'V' + i.toString().padLeft(98, '0')),
        verseCandidates: List.generate(
            8,
            (i) => {
                  'id': 'V' + i.toString().padLeft(98, '0'),
                  'tags': List.filled(8, '태' * 40)
                }));
    final payload = request.toJson();
    expect(utf8.encode(jsonEncode(payload)).length, lessThanOrEqualTo(15000));
    expect(payload['userMessage'], current);
    final wire = payload['session']['personalizationContext'];
    expect(wire['emotion'], '불안');
    expect(wire['intensity'], 8);
    expect(wire['desiredHelp'], 'rest');
    expect(wire['historyCompacted'], true);
    expect((wire['alreadyAnswered'] as List).last, '');
    expect(c.answers, hasLength(5));
    expect(c.answers.first.length, greaterThan(1900));
    expect(session.summary.length, 4000);
    expect(session.agentMemory.length, 4000);
    expect(payload['allowedVerseIds'], isNotEmpty);
  });
}
