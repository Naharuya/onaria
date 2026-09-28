import 'check_in.dart';
import 'crisis_detector.dart';

/// Selected by the application composition root, never inferred from user text.
enum ReligionProfile { christian, buddhist }

enum ConversationPhase {
  emotion,
  situation,
  thought,
  need,
  sourceOffer,
  sourceReflection,
  action,
  summary,
  crisis,
  ended,
}

/// In-memory, religion-neutral state. Contains no scripture or API wire format.
class ConversationState {
  const ConversationState._({
    required this.profile,
    this.phase = ConversationPhase.emotion,
    this.checkIn,
    this.turnCount = 0,
    this.riskLevel = 0,
  });

  factory ConversationState.start(ReligionProfile profile) =>
      ConversationState._(profile: profile);

  final ReligionProfile profile;
  final ConversationPhase phase;
  final CheckInInput? checkIn;
  final int turnCount;
  final int riskLevel;
  bool get isCrisis => riskLevel > 0;

  ConversationState beginCheckIn(CheckInInput input) => _assess(
        input.customEmotion ?? '',
        input,
      );

  /// Safety precedes the profile boundary. Callers must stop on isCrisis before
  /// invoking any provider, agent, psychology service or model client.
  ConversationState acceptInput(String input,
      {required ReligionProfile requestedProfile}) {
    final assessed = _assess(input, checkIn);
    if (assessed.isCrisis) return assessed;
    if (requestedProfile != profile) throw StateError('PACK_MISMATCH');
    return ConversationState._(
      profile: profile,
      phase: ConversationPhase.sourceReflection,
      checkIn: checkIn,
      turnCount: turnCount + 1,
    );
  }

  ConversationState _assess(String input, CheckInInput? nextCheckIn) {
    const detector = CrisisDetector();
    var risk = riskLevel;
    for (final text in [input, nextCheckIn?.customEmotion ?? '']) {
      final level = detector.assess(text).level;
      if (level > risk) risk = level;
    }
    return ConversationState._(
      profile: profile,
      phase: risk > 0 ? ConversationPhase.crisis : phase,
      checkIn: nextCheckIn,
      turnCount: turnCount,
      riskLevel: risk,
    );
  }
}
