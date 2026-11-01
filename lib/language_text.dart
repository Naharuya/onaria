import 'package:flutter/material.dart';

/// Presentation only. Korean/other scripts inherit the existing text style.
/// No translation, text normalization, storage or provider changes occur here.
class LanguageColors {
  static Color english(BuildContext context) => _readable(context, false);
  static Color han(BuildContext context) => _readable(context, true);
  static Color _readable(BuildContext context, bool han) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.surface.computeLuminance() < .35;
    final tint = dark
        ? (han ? const Color(0xFFC6AA8B) : const Color(0xFF9BB4C6))
        : (han ? const Color(0xFF87684E) : const Color(0xFF526F82));
    final surfaces = [scheme.surface, scheme.surfaceContainerHighest];
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
    }

    for (var i = 0; i <= 20; i++) {
      final candidate = Color.lerp(tint, scheme.onSurface, i / 20)!;
      if (surfaces
          .every((background) => contrast(candidate, background) >= 4.5))
        return candidate;
    }
    return scheme.onSurface;
  }

  static TextSpan span(BuildContext context, String text) {
    int kind(int rune) {
      if ((rune >= 0x41 && rune <= 0x5a) ||
          (rune >= 0x61 && rune <= 0x7a) ||
          (rune >= 0xc0 && rune <= 0x24f)) return 1;
      if ((rune >= 0x3400 && rune <= 0x4dbf) ||
          (rune >= 0x4e00 && rune <= 0x9fff) ||
          (rune >= 0xf900 && rune <= 0xfaff) ||
          (rune >= 0x20000 && rune <= 0x323af)) return 2;
      return 0;
    }

    final spans = <TextSpan>[];
    var buffer = StringBuffer();
    int? previous;
    void flush() {
      if (buffer.isEmpty) return;
      spans.add(TextSpan(
          text: buffer.toString(),
          style: previous == 1
              ? TextStyle(color: english(context))
              : previous == 2
                  ? TextStyle(color: han(context))
                  : null));
      buffer = StringBuffer();
    }

    for (final rune in text.runes) {
      final mark = (rune >= 0x300 && rune <= 0x36f) ||
          (rune >= 0xfe00 && rune <= 0xfe0f) ||
          (rune >= 0xe0100 && rune <= 0xe01ef);
      final next = mark ? (previous ?? 0) : kind(rune);
      if (previous != null && next != previous) flush();
      previous = next;
      buffer.writeCharCode(rune);
    }
    flush();
    return TextSpan(children: spans);
  }
}

class LanguageText extends StatelessWidget {
  const LanguageText(this.data,
      {super.key, this.style, this.textAlign, this.maxLines, this.overflow});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  @override
  Widget build(BuildContext context) =>
      Text.rich(LanguageColors.span(context, data),
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow);
}

class LanguageSelectableText extends StatelessWidget {
  const LanguageSelectableText(this.data,
      {super.key, this.style, this.textAlign, this.maxLines});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  @override
  Widget build(BuildContext context) =>
      SelectableText.rich(LanguageColors.span(context, data),
          style: style, textAlign: textAlign, maxLines: maxLines);
}
