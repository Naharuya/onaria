import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/onaria.dart';

void main() {
  const machine = ConversationMachine();
  const session = ConversationSession(
      sessionId: 'isolated-test',
      selectedEmotion: EmotionType.gratitude,
      emotionIntensity: 5,
      stage: ConversationStage.need,
      turnCount: 4);
  test(
      'safe final budget response offers content even when model asks to continue',
      () {
    final result = machine.applyLlmResponse(
        session,
        const LlmConversationResponse(
            message: '차분히 돌아봐요.',
            stage: ConversationStage.need,
            detectedEmotion: EmotionType.gratitude,
            riskLevel: 0,
            shouldOfferVerse: false,
            shouldEndConversation: false,
            continueConversation: true));
    expect(result.session.stage, ConversationStage.verseOffer);
    expect(result.uiAction, ConversationUiAction.showVerseConsent);
  });
  test('explicit end remains ended; user decides subsequent local journey', () {
    final result = machine.applyLlmResponse(
        session,
        const LlmConversationResponse(
            message: '여기서 마칠게요.',
            stage: ConversationStage.ended,
            detectedEmotion: EmotionType.gratitude,
            riskLevel: 0,
            shouldOfferVerse: false,
            shouldEndConversation: true));
    expect(result.session.isEnded, isTrue);
    expect(result.uiAction, ConversationUiAction.end);
  });
  test('risk at budget boundary cannot become content or practice', () {
    final result = machine.applyLlmResponse(
        session,
        const LlmConversationResponse(
            message: 'not displayed',
            stage: ConversationStage.crisis,
            detectedEmotion: EmotionType.gratitude,
            riskLevel: 3,
            shouldOfferVerse: true,
            shouldEndConversation: true));
    expect(result.session.stage, ConversationStage.crisis);
    expect(result.uiAction, ConversationUiAction.showEmergencySupport);
  });
}
