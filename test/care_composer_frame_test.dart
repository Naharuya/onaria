import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/care_composer_frame.dart';

void main() {
  testWidgets('outline encloses controls and highlight hides on input focus',
      (t) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CareComposerFrame(
                child: Row(children: [
      Expanded(child: TextField(focusNode: focus)),
      IconButton(
          onPressed: () {}, icon: const Icon(Icons.arrow_upward_rounded)),
      IconButton(onPressed: () {}, icon: const Icon(Icons.mic_rounded)),
    ])))));
    final highlight = find.byKey(const ValueKey('care-composer-highlight'));
    expect(highlight, findsOneWidget);
    final rect = t.getRect(find.byKey(const ValueKey('care-composer-outline')));
    for (final icon in [Icons.arrow_upward_rounded, Icons.mic_rounded]) {
      expect(rect.contains(t.getCenter(find.byIcon(icon))), isTrue);
    }
    await t.pump(const Duration(seconds: 1));
    expect(t.binding.transientCallbackCount, greaterThan(0));
    await t.tap(find.byType(TextField));
    await t.pump();
    expect(highlight, findsNothing);
    expect(find.byKey(const ValueKey('care-composer-outline')), findsOneWidget);
    focus.unfocus();
    await t.pump();
    expect(highlight, findsOneWidget);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    expect(highlight, findsNothing);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(highlight, findsOneWidget);
    await t.pumpWidget(const SizedBox());
    expect(t.takeException(), isNull);
  });
  testWidgets('reduced motion keeps plain outline without orbit', (t) async {
    await t.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: CareComposerFrame(child: Text('input')))));
    expect(find.byKey(const ValueKey('care-composer-outline')), findsOneWidget);
    expect(find.byKey(const ValueKey('care-composer-highlight')), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
}
