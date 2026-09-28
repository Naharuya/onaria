import 'emotion.dart';

/// Religion-neutral, immutable input. No storage, network or scripture lookup.
class CheckInInput {
  CheckInInput({
    required this.emotion,
    required this.intensity,
    String? customEmotion,
  }) : customEmotion = _normalize(customEmotion) {
    RangeError.checkValueInInterval(intensity, 1, 10, 'intensity');
  }

  static const maxCustomEmotionLength = 2000;
  final EmotionType emotion;
  final int intensity;
  final String? customEmotion;

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.length > maxCustomEmotionLength) {
      throw ArgumentError('customEmotion exceeds maximum length');
    }
    return trimmed;
  }
}
