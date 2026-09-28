import 'package:flutter_test/flutter_test.dart';
import 'package:onaria_core/onaria_core.dart';
import 'package:onaria/src/conversation/conversation_models.dart';
import 'package:onaria/src/conversation/core_phase_adapter.dart';

void main() {
  test('Every Christian stage keeps its exact legacy wire representation', () {
    const wires = [
      'emotion',
      'situation',
      'thought',
      'need',
      'verse_offer',
      'verse_reflection',
      'action',
      'summary',
      'crisis',
      'ended',
    ];
    for (var i = 0; i < wires.length; i++) {
      final legacy = ConversationStage.fromWire(wires[i]);
      expect(legacy, ConversationStage.values[i]);
      expect(christianStageFromCore(legacy.corePhase).wireName, wires[i]);
      final session = ConversationSession(
        sessionId: 'test',
        selectedEmotion: EmotionType.anxiety,
        emotionIntensity: 5,
        stage: legacy,
      );
      expect(session.toJson()['currentStage'], wires[i]);
      expect(session.toJson().containsKey('profile'), isFalse);
    }
  });

  test('Both fixed profiles reject cross-pack input without changing state',
      () {
    for (final profile in ReligionProfile.values) {
      final state = ConversationState.start(profile);
      final other = ReligionProfile.values.firstWhere((p) => p != profile);
      expect(() => state.acceptInput('불안', requestedProfile: other),
          throwsStateError);
      expect(state.turnCount, 0);
      expect(state.profile, profile);
      final next = state.acceptInput('불안', requestedProfile: profile);
      expect(next.turnCount, 1);
      expect(next.profile, profile);
      expect(state.turnCount, 0);
    }
  });

  test('Safety precedes mismatch and cannot be reset by a new check-in', () {
    final state = ConversationState.start(ReligionProfile.buddhist);
    final crisis = state.acceptInput('죽고 싶어요',
        requestedProfile: ReligionProfile.christian);
    expect(crisis.isCrisis, isTrue);
    expect(crisis.phase, ConversationPhase.crisis);
    expect(crisis.turnCount, 0);
    final later = crisis
        .beginCheckIn(CheckInInput(emotion: EmotionType.joy, intensity: 1))
        .acceptInput('감사', requestedProfile: ReligionProfile.buddhist);
    expect(later.riskLevel, crisis.riskLevel);
    expect(later.phase, ConversationPhase.crisis);
    expect(later.turnCount, 0);
  });
}
