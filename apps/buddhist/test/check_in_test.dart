import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria_buddhist/main.dart';
import 'package:onaria_buddhist/session.dart';
import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:onaria_core/onaria_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountingProvider extends Fake implements BuddhistScriptureProvider {
  CountingProvider(this.delegate);
  final BuddhistScriptureProvider delegate;
  int searchCalls = 0;
  @override
  List<MockScripture> search(String query) {
    searchCalls++;
    return delegate.search(query);
  }

  @override
  MockScripture? getById(String id) => delegate.getById(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CountingProvider provider;
  late SharedPreferences preferences;
  late BuddhistSession session;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    provider = CountingProvider(await BuddhistScriptureProvider.load());
    session = BuddhistSession(provider, preferences);
  });

  test(
      'Check-in intercepts all risk fixtures before conversation/retrieval; false positives stay usable',
      () {
    final cases = jsonDecode(
            File('../../backend_contract/safety_cases.json').readAsStringSync())
        as List;
    for (final row in cases) {
      final current = BuddhistSession(provider, preferences);
      final checkIn = CheckInInput(
          emotion: EmotionType.gratitude,
          intensity: 1,
          customEmotion: row['text'] as String);
      final before = provider.searchCalls;
      final ready = current.beginCheckIn(checkIn);
      expect(current.checkIn, same(checkIn));
      expect(current.riskLevel, row['level'], reason: row['id'] as String);
      expect(provider.searchCalls, before);
      expect(ready, row['level'] == 0);
      if (!ready) {
        expect(current.message, localCrisisMessage(row['level'] as int));
        current.respond('불안');
        expect(provider.searchCalls, before);
        expect(current.citations, isEmpty);
        expect(
            current.beginCheckIn(
                CheckInInput(emotion: EmotionType.joy, intensity: 1)),
            isFalse);
        expect(current.riskLevel, row['level']);
      } else {
        current.respond('불안');
        expect(provider.searchCalls, before + 1);
      }
    }
  });

  test(
      'Check-in retains custom input and intensity without persisting private text',
      () {
    final checkIn = CheckInInput(
        emotion: EmotionType.exhaustion,
        intensity: 8,
        customEmotion: '  쉬고 싶어요  ');
    expect(session.beginCheckIn(checkIn), isTrue);
    session.respond('지침');
    expect(session.checkIn, same(checkIn));
    expect(session.checkIn!.customEmotion, '쉬고 싶어요');
    expect(session.checkIn!.intensity, 8);
    expect(preferences.getKeys(), isEmpty);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
        '16 emotions, intensity and custom text reach session at text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(BuddhistApp(session: session));
      expect(find.byType(ChoiceChip), findsNWidgets(16));
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, '질투'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '질투'));
      await tester.pumpAndSettle();
      final slider = find.byKey(const Key('emotion-intensity'));
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getBottomRight(slider) - const Offset(25, 24));
      await tester.pumpAndSettle();
      final selectedIntensity = tester.widget<Slider>(slider).value.round();
      expect(selectedIntensity, greaterThan(5));
      await tester.enterText(find.byType(TextField), '  쉬고 싶은 불안  ');
      await tester.ensureVisible(find.text('마음 살펴보기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('마음 살펴보기'));
      await tester.pumpAndSettle();
      expect(session.checkIn!.emotion, EmotionType.jealousy);
      expect(session.checkIn!.intensity, selectedIntensity);
      expect(session.checkIn!.customEmotion, '쉬고 싶은 불안');
      expect(provider.searchCalls, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'UI custom crisis bypasses retrieval and card creation at any selected emotion',
      (tester) async {
    await tester.pumpWidget(BuddhistApp(session: session));
    await tester.enterText(find.byType(TextField), '죽고 싶어요');
    await tester.ensureVisible(find.text('마음 살펴보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마음 살펴보기'));
    await tester.pumpAndSettle();
    expect(session.checkIn!.customEmotion, '죽고 싶어요');
    expect(session.message, contains('109'));
    expect(provider.searchCalls, 0);
    expect(find.text('마음카드 만들기'), findsNothing);
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
  });
}
