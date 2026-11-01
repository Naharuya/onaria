import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/app_theme.dart';
import 'package:onaria/app/quiet_composer_frame.dart';

void main() {
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets(
        'composer encloses input and controls; motion respects lifecycle at $width',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      Widget screen(bool reduced) => MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
              data: MediaQueryData(
                  size: Size(width, 844), disableAnimations: reduced),
              child: Scaffold(
                  body: Center(
                      child: SizedBox(
                          width: width - 32,
                          child: QuietComposerFrame(
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                const Expanded(
                                    child: TextField(
                                        minLines: 1,
                                        maxLines: 4,
                                        decoration: InputDecoration(
                                            border: InputBorder.none))),
                                IconButton(
                                    onPressed: () {},
                                    tooltip: '보내기',
                                    icon: const Icon(Icons.arrow_upward)),
                                IconButton(
                                    onPressed: () {},
                                    tooltip: '마이크',
                                    icon: const Icon(Icons.mic)),
                              ])))))));
      await tester.pumpWidget(screen(false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      final frame = tester.getRect(find.byType(QuietComposerFrame));
      for (final finder in [
        find.byType(TextField),
        find.byTooltip('보내기'),
        find.byTooltip('마이크')
      ]) {
        final rect = tester.getRect(finder);
        expect(frame.contains(rect.topLeft), isTrue);
        expect(frame.contains(rect.bottomRight), isTrue);
      }
      (tester.state(find.byType(QuietComposerFrame)) as WidgetsBindingObserver).didChangeAppLifecycleState(AppLifecycleState.inactive);
      (tester.state(find.byType(QuietComposerFrame)) as WidgetsBindingObserver).didChangeAppLifecycleState(AppLifecycleState.hidden);
      (tester.state(find.byType(QuietComposerFrame)) as WidgetsBindingObserver).didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      (tester.state(find.byType(QuietComposerFrame)) as WidgetsBindingObserver).didChangeAppLifecycleState(AppLifecycleState.hidden);
      (tester.state(find.byType(QuietComposerFrame)) as WidgetsBindingObserver).didChangeAppLifecycleState(AppLifecycleState.inactive);
      (tester.state(find.byType(QuietComposerFrame)) as WidgetsBindingObserver).didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(screen(true));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
