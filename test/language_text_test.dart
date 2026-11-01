import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/language_text.dart';

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets(
        'Korean inherits existing color and English/Han remain readable: $brightness',
        (t) async {
      final theme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal, brightness: brightness));
      const original = '한글 원문 Love 仁愛 𠀀 · 123 😊 e\u0301 漢\ufe00';
      late TextSpan span;
      late Color english, han;
      await t.pumpWidget(MaterialApp(
          theme: theme,
          home: Builder(builder: (context) {
            span = LanguageColors.span(context, original);
            english = LanguageColors.english(context);
            han = LanguageColors.han(context);
            return const Scaffold(
                body: DefaultTextStyle(
                    style: TextStyle(color: Colors.purple, fontSize: 17),
                    child: LanguageText(original)));
          })));
      expect(span.toPlainText(), original);
      final children = span.children!.cast<TextSpan>().toList();
      expect(children.first.style, isNull);
      expect(
          children.firstWhere((s) => s.text == 'Love').style!.color, english);
      expect(children.firstWhere((s) => s.text == '仁愛').style!.color, han);
      expect(children.firstWhere((s) => s.text == '𠀀').style!.color, han);
      expect(children.firstWhere((s) => s.text == 'e\u0301').style!.color,
          english);
      expect(children.firstWhere((s) => s.text == '漢\ufe00').style!.color, han);
      final rendered = t.widget<Text>(find.byType(Text));
      expect(rendered.textSpan!.toPlainText(), original);
      for (final color in [english, han]) {
        for (final background in [
          theme.colorScheme.surface,
          theme.colorScheme.surfaceContainerHighest
        ]) {
          final x = color.computeLuminance(), y = background.computeLuminance();
          expect(((x > y ? x : y) + .05) / ((x > y ? y : x) + .05),
              greaterThanOrEqualTo(4.5));
        }
      }
      expect(english, isNot(han));
    });
  }
  testWidgets('selection text and large text preserve content without overflow',
      (t) async {
    const text = '한국어 번역 · English original · 漢文 原文';
    await t.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
                body: SizedBox(
                    width: 280,
                    child: Column(children: [
                      const LanguageSelectableText(text),
                      LanguageText(text,
                          maxLines: 2, overflow: TextOverflow.ellipsis)
                    ]))))));
    final selected = t.widget<SelectableText>(find.byType(SelectableText));
    expect(selected.textSpan!.toPlainText(), text);
    expect(t.takeException(), isNull);
  });
}
