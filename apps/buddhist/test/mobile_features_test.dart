import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria_buddhist/main.dart';
import 'package:onaria_buddhist/session.dart';
import 'package:onaria_buddhist/mind_card_store.dart';
import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.onaria.buddhist/offline');
  final calls = <MethodCall>[];
  late BuddhistSession session;
  setUp(() async {
    calls.clear();
    SharedPreferences.setMockInitialValues({
      MindCardStore.legacyKey: ['test-buddhist-calm']
    });
    session = BuddhistSession(await BuddhistScriptureProvider.load(),
        await SharedPreferences.getInstance());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'Growth → reminder → preview → share chooser → speech → Safety at text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      Future<void> tap(String text) async {
        await tester.scrollUntilVisible(find.text(text), 200,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(text));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(BuddhistApp(session: session));
      await tester.tap(find.text('저장·성장'));
      await tester.pumpAndSettle();
      await tap('1분 뒤 알림 테스트');
      expect(calls.last.method, 'reminder');
      expect(calls.last.arguments, {'minutes': 1});
      await tap('알림 취소');
      expect(calls.last.method, 'cancelReminder');
      await tap('카드 자세히 보기');
      await tap('공유 내용 미리보기');
      expect(calls.where((call) => call.method == 'share'), isEmpty);
      await tap('공유 앱 선택');
      final text = calls.last.arguments['text'] as String;
      expect(text, startsWith('TEST_DATA_ONLY'));
      expect(text, contains(session.savedCards.single.text));
      await tap('오프라인 음성으로 읽기');
      expect(calls.last.method, 'speak');
      session.respond('죽고 싶어요');
      await tester.pumpWidget(BuddhistApp(session: session));
      await tester.pumpAndSettle();
      expect(calls.any((call) => call.method == 'safetyStop'), isTrue);
      expect(find.text('공유 앱 선택'), findsNothing);
      expect(find.text('오프라인 음성으로 읽기'), findsNothing);
    });
  }
}
