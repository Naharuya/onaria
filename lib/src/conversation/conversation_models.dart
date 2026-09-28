import 'package:onaria_core/onaria_core.dart' show EmotionType;

export 'package:onaria_core/onaria_core.dart' show EmotionType;

enum ConversationStage {
  emotion,
  situation,
  thought,
  need,
  verseOffer,
  verseReflection,
  action,
  summary,
  crisis,
  ended;

  String get wireName => switch (this) {
        ConversationStage.verseOffer => 'verse_offer',
        ConversationStage.verseReflection => 'verse_reflection',
        _ => name,
      };

  static ConversationStage fromWire(String value) {
    return switch (value) {
      'verse_offer' => ConversationStage.verseOffer,
      'verse_reflection' => ConversationStage.verseReflection,
      'ended' => ConversationStage.ended,
      _ => ConversationStage.values.firstWhere(
          (stage) => stage.name == value,
          orElse: () => ConversationStage.emotion,
        ),
    };
  }
}

class ConversationSession {
  const ConversationSession({
    required this.sessionId,
    required this.selectedEmotion,
    required this.emotionIntensity,
    this.customEmotion,
    this.stage = ConversationStage.emotion,
    this.turnCount = 0,
    this.summary = '',
    this.lastUserMessage,
    this.lastAssistantQuestion,
    this.verseAccepted,
    this.selectedVerseId,
    this.riskLevel = 0,
    this.agentMemory = '',
    this.isEnded = false,
  });

  final String sessionId;
  final EmotionType selectedEmotion;
  final int emotionIntensity;
  final String? customEmotion;
  final ConversationStage stage;
  final int turnCount;
  final String summary;
  final String? lastUserMessage;
  final String? lastAssistantQuestion;
  final bool? verseAccepted;
  final String? selectedVerseId;
  final int riskLevel;
  final String agentMemory;
  final bool isEnded;

  ConversationSession copyWith({
    ConversationStage? stage,
    int? turnCount,
    String? summary,
    String? lastUserMessage,
    String? lastAssistantQuestion,
    bool? verseAccepted,
    String? selectedVerseId,
    int? riskLevel,
    String? agentMemory,
    bool? isEnded,
  }) {
    return ConversationSession(
      sessionId: sessionId,
      selectedEmotion: selectedEmotion,
      emotionIntensity: emotionIntensity,
      customEmotion: customEmotion,
      stage: stage ?? this.stage,
      turnCount: turnCount ?? this.turnCount,
      summary: summary ?? this.summary,
      lastUserMessage: lastUserMessage ?? this.lastUserMessage,
      lastAssistantQuestion:
          lastAssistantQuestion ?? this.lastAssistantQuestion,
      verseAccepted: verseAccepted ?? this.verseAccepted,
      selectedVerseId: selectedVerseId ?? this.selectedVerseId,
      riskLevel: riskLevel ?? this.riskLevel,
      agentMemory: agentMemory ?? this.agentMemory,
      isEnded: isEnded ?? this.isEnded,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'selectedEmotion': selectedEmotion.label,
        if (customEmotion != null) 'customEmotion': customEmotion,
        'emotionIntensity': emotionIntensity,
        'currentStage': stage.wireName,
        'turnCount': turnCount,
        'conversationSummary': summary,
        'previousUserAnswer': lastUserMessage,
        'previousAssistantQuestion': lastAssistantQuestion,
        'verseAccepted': verseAccepted,
        'selectedVerse': selectedVerseId,
        'riskLevel': riskLevel,
        'conversationMemory': agentMemory,
      };
}
