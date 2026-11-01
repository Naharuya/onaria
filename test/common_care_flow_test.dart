import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/care_flow.dart';

void main() {
  test('five stages have one stable order and no provider dependency', () {
    expect(CareFlow.order, [
      CareStep.emotion,
      CareStep.conversation,
      CareStep.content,
      CareStep.practice,
      CareStep.card
    ]);
    expect(CareFlow.step(summary: true, actions: true, content: true),
        CareStep.card);
    expect(CareFlow.step(summary: false, actions: true, content: true),
        CareStep.practice);
    expect(CareFlow.step(summary: false, actions: false, content: true),
        CareStep.content);
  });
  test('risk, pending response and stale route cannot advance', () {
    for (final risk in [1, 2, 3]) {
      expect(CareFlow.canAdvance(riskLevel: risk, busy: false), isFalse);
    }
    expect(CareFlow.canAdvance(riskLevel: 0, busy: true), isFalse);
    expect(CareFlow.canAdvance(riskLevel: 0, busy: false, current: false),
        isFalse);
    expect(CareFlow.canAdvance(riskLevel: 0, busy: false), isTrue);
  });
  testWidgets(
      'stage indicator wraps at narrow width with large text and is not navigation',
      (t) async {
    t.view.physicalSize = const Size(320, 720);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Scaffold(
                body: CareFlowProgress(
                    step: CareStep.content, contentLabel: '말씀')))));
    expect(find.text('3/5 · 말씀'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
    expect(t.takeException(), isNull);
  });
}
