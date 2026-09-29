import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/engagement/mini_games/cross_light/cross_light_game.dart';
import 'package:onaria/engagement/mini_games/cross_light/cross_light_page.dart';

void main() {
  for (final fromMindCard in [false, true]) {
    testWidgets(
        'controls change after collecting all stars (mind card: $fromMindCard)',
        (tester) async {
      var now = DateTime(2026, 9, 29);
      final game = CrossLightGame(clock: () => now);
      await tester.pumpWidget(MaterialApp(
          home: CrossLightPage(game: game, continueToMindCard: fromMindCard)));

      final words = crossLightWords.keys.toList();
      for (var i = 0; i < words.length; i++) {
        final star = find.byKey(ValueKey('cross-light-touch-${words[i]}'));
        await tester.ensureVisible(star);
        await tester.tap(star);
        await tester.pump();
        if (i == 0) {
          await tester.scrollUntilVisible(find.text('이번에는 여기까지'), 180);
          expect(find.widgetWithText(TextButton, '잠시 쉬기'), findsOneWidget);
          expect(find.widgetWithText(TextButton, '처음부터'), findsOneWidget);
          expect(find.widgetWithText(TextButton, '이번에는 여기까지'), findsOneWidget);
        }
        now = now.add(const Duration(seconds: 5));
        await tester.pump(const Duration(seconds: 5));
      }

      expect(game.complete, isTrue);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('한 번 더 빛 모으기'), 180);
      expect(find.text('잠시 쉬기'), findsNothing);
      expect(find.text('처음부터'), findsNothing);
      expect(find.text('이번에는 여기까지'), findsNothing);
      expect(
          find.widgetWithText(
              FilledButton, fromMindCard ? '작은 성장 기록 보기' : '편안히 돌아가기'),
          findsOneWidget);
      expect(find.widgetWithText(TextButton, '한 번 더 빛 모으기'), findsOneWidget);
      await tester.tap(find.text('한 번 더 빛 모으기'));
      // The active game's star animation keeps scheduling frames after replay.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(game.complete, isFalse);
      expect(game.pieces, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
