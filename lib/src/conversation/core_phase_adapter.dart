import 'package:onaria_core/onaria_core.dart';

import 'conversation_models.dart';

/// Legacy Christian wire names stay in ConversationStage, outside Core.
extension ChristianCorePhase on ConversationStage {
  ConversationPhase get corePhase => switch (this) {
        ConversationStage.emotion => ConversationPhase.emotion,
        ConversationStage.situation => ConversationPhase.situation,
        ConversationStage.thought => ConversationPhase.thought,
        ConversationStage.need => ConversationPhase.need,
        ConversationStage.verseOffer => ConversationPhase.sourceOffer,
        ConversationStage.verseReflection => ConversationPhase.sourceReflection,
        ConversationStage.action => ConversationPhase.action,
        ConversationStage.summary => ConversationPhase.summary,
        ConversationStage.crisis => ConversationPhase.crisis,
        ConversationStage.ended => ConversationPhase.ended,
      };
}

ConversationStage christianStageFromCore(ConversationPhase phase) =>
    switch (phase) {
      ConversationPhase.emotion => ConversationStage.emotion,
      ConversationPhase.situation => ConversationStage.situation,
      ConversationPhase.thought => ConversationStage.thought,
      ConversationPhase.need => ConversationStage.need,
      ConversationPhase.sourceOffer => ConversationStage.verseOffer,
      ConversationPhase.sourceReflection => ConversationStage.verseReflection,
      ConversationPhase.action => ConversationStage.action,
      ConversationPhase.summary => ConversationStage.summary,
      ConversationPhase.crisis => ConversationStage.crisis,
      ConversationPhase.ended => ConversationStage.ended,
    };
