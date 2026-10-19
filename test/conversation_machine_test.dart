import 'package:onaria/onaria.dart';
import 'package:test/test.dart';

void main() {
  const machine = ConversationMachine();

  final base = ConversationSession(
    sessionId: 's1',
    selectedEmotion: EmotionType.anxiety,
    emotionIntensity: 4,
  );

  test('adaptive response continues beyond three turns and closes at five', () {
    const response = LlmConversationResponse(
      message: '지금 필요한 것을 더 살펴볼게요.',
      question: '어떤 도움이 필요할까요?',
      stage: ConversationStage.need,
      detectedEmotion: EmotionType.anxiety,
      riskLevel: 0,
      shouldOfferVerse: false,
      shouldEndConversation: false,
      continueConversation: true,
      responseMode: 'ai',
    );
    var session = base;
    for (var turn = 1; turn <= 5; turn++) {
      final result = machine.applyLlmResponse(session, response);
      expect(
          result.uiAction,
          turn == 5
              ? ConversationUiAction.end
              : ConversationUiAction.showMessage);
      expect(result.session.isEnded, turn == 5);
      session = result.session;
    }
    final parsed = LlmConversationResponse.fromJson(response.toJson());
    expect(parsed.continueConversation, isTrue);
    expect(parsed.responseMode, 'ai');
  });

  test('3턴 이전 말씀 점프를 차단한다', () {
    final response = LlmConversationResponse(
      message: '말씀을 살펴볼 수 있어요.',
      question: '말씀을 볼까요?',
      stage: ConversationStage.verseOffer,
      detectedEmotion: EmotionType.anxiety,
      riskLevel: 0,
      shouldOfferVerse: true,
      shouldEndConversation: false,
    );

    final result = machine.applyLlmResponse(base, response);
    expect(result.session.stage, ConversationStage.need);
  });

  test('위기 응답은 위기 UI로 전환한다', () {
    final response = LlmConversationResponse(
      message: '안전을 먼저 확인해야 합니다.',
      question: '구체적인 계획이 있나요?',
      stage: ConversationStage.crisis,
      detectedEmotion: EmotionType.sadness,
      riskLevel: 2,
      shouldOfferVerse: false,
      shouldEndConversation: false,
    );

    final result = machine.applyLlmResponse(base, response);
    expect(result.uiAction, ConversationUiAction.showCrisisSupport);
    expect(result.session.riskLevel, 2);
    expect(result.session.isEnded, isTrue);
  });

  test('서버가 질문을 더 보내도 세 번째 답변 후 말씀으로 전환한다', () {
    final response = LlmConversationResponse(
      message: '마음을 돌아볼게요.',
      question: '추가 질문입니다.',
      stage: ConversationStage.situation,
      detectedEmotion: EmotionType.anxiety,
      riskLevel: 0,
      shouldOfferVerse: false,
      shouldEndConversation: false,
    );
    var session = base;
    for (var answer = 1; answer <= 3; answer++) {
      final result = machine.applyLlmResponse(session, response);
      expect(
          result.uiAction,
          answer == 3
              ? ConversationUiAction.showVerseConsent
              : ConversationUiAction.showMessage);
      expect(result.session.isEnded, isFalse);
      session = result.session;
    }
    expect(session.stage, ConversationStage.verseOffer);
  });

  test('서버 종료 응답은 종료 상태와 종료 액션으로 전환한다', () {
    final response = LlmConversationResponse(
      message: '오늘 대화를 마칠게요.',
      stage: ConversationStage.summary,
      detectedEmotion: EmotionType.anxiety,
      riskLevel: 0,
      shouldOfferVerse: false,
      shouldEndConversation: true,
    );

    final result = machine.applyLlmResponse(base, response);
    expect(result.session.stage, ConversationStage.ended);
    expect(result.session.isEnded, isTrue);
    expect(result.uiAction, ConversationUiAction.end);
  });
}
