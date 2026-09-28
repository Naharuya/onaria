import 'package:onaria_core/onaria_core.dart';

/// Local-only contract. No credentials, HTTP client or generated quotation text.
class LocalConversationRequest {
  LocalConversationRequest(
      {required this.emotion,
      required this.intensity,
      required this.phase,
      required this.input,
      required List<String> previousInputs})
      : previousInputs = List.unmodifiable(previousInputs);
  final ReligionProfile profile = ReligionProfile.buddhist;
  final EmotionType emotion;
  final int intensity;
  final ConversationPhase phase;
  final String input;
  final List<String> previousInputs;
}

abstract class LocalConversationClient {
  Map<String, Object?> respond(LocalConversationRequest request);
}

class MockConversationClient implements LocalConversationClient {
  const MockConversationClient();
  @override
  Map<String, Object?> respond(LocalConversationRequest request) {
    final rest = [...request.previousInputs, request.input]
        .any((text) => text.contains('쉬') || text.contains('쉼'));
    return {
      'profile': 'buddhist',
      'phase': request.phase.name,
      'template': switch (request.phase) {
        ConversationPhase.need =>
          request.intensity >= 8 ? 'gentleNeed' : 'need',
        ConversationPhase.sourceOffer => rest ? 'restOffer' : 'sourceOffer',
        ConversationPhase.action => 'action',
        _ => throw StateError('INVALID_PHASE'),
      },
    };
  }
}

/// Untrusted client output is a closed template selection, never display prose.
String validatedLocalReply(
    Map<String, Object?> response, LocalConversationRequest request) {
  if (response.length != 3 ||
      response['profile'] != 'buddhist' ||
      response['phase'] != request.phase.name) {
    throw StateError('INVALID_REPLY');
  }
  final allowed = switch (request.phase) {
    ConversationPhase.need => const ['need', 'gentleNeed'],
    ConversationPhase.sourceOffer => const ['sourceOffer', 'restOffer'],
    ConversationPhase.action => const ['action'],
    _ => const <String>[],
  };
  final template = response['template'];
  if (!allowed.contains(template)) throw StateError('INVALID_REPLY');
  return switch (template) {
    'need' => '${request.emotion.label}의 마음을 돌아보고 계시군요. 지금 나에게 필요한 것은 무엇인가요?',
    'gentleNeed' =>
      '마음의 강도를 ${request.intensity}/10으로 알려 주셨어요. 서두르지 않아도 괜찮습니다. 지금 가장 필요한 작은 도움은 무엇인가요?',
    'restOffer' =>
      '쉼에 관해 이야기해 주셨네요. 마음을 돌아볼 합성 테스트 자료를 볼까요? 실제 경전이나 번역문은 아닙니다.',
    'sourceOffer' => '마음을 돌아볼 합성 테스트 자료를 볼까요? 실제 경전이나 번역문은 아닙니다.',
    _ => '오늘 할 수 있는 작은 실천을 하나 골라 주세요. 선택하지 않아도 괜찮습니다.',
  };
}
