import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria_buddhist/main.dart';
import 'package:onaria_buddhist/session.dart';
import 'package:onaria_buddhist/mind_card_store.dart';
import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late BuddhistScriptureProvider provider;
  final timestamp = DateTime.utc(2026, 9, 28, 3, 4, 5);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    provider = await BuddhistScriptureProvider.load();
  });
  BuddhistSession session({MindCardStore? store}) =>
      BuddhistSession(provider, prefs, cardStore: store);
  void prepare(BuddhistSession current, [String query = '불안']) {
    current.respond(query);
    current.makeCard(current.citations.first.id);
  }

  test(
      'Save/reload stores references and UTC time only; duplicate keeps original date',
      () async {
    final store = MindCardStore(prefs, clock: () => timestamp);
    final current = session(store: store);
    prepare(current);
    await current.saveCard();
    final payload = prefs.getString(MindCardStore.storageKey)!;
    final row = (jsonDecode(payload)['cards'] as List).single as Map;
    expect(row.keys.toSet(), {'scriptureId', 'savedAt'});
    expect(row['savedAt'], timestamp.toIso8601String());
    expect(payload, isNot(contains(current.card!.text)));
    final restored = session();
    final detail = restored.savedDetail(current.card!.id)!;
    expect(detail.savedAt, timestamp);
    expect(detail.scripture.text, current.card!.text);
    expect(detail.scripture.source, provider.getSource(current.card!.id));
    prepare(restored);
    await restored.saveCard();
    expect(prefs.getString(MindCardStore.storageKey), payload);
    expect(restored.savedDetails, hasLength(1));
    expect(() => restored.savedIds.add('forged'), throwsUnsupportedError);
  });

  test(
      'Legacy IDs stay intact; unknown/foreign IDs never appear and date is not invented',
      () async {
    const legacy = [
      'test-buddhist-calm',
      'christian-id',
      'BLOCKED_EXTERNAL_REVIEW'
    ];
    await prefs.setStringList(MindCardStore.legacyKey, legacy);
    final current =
        session(store: MindCardStore(prefs, clock: () => timestamp));
    expect(current.savedDetails.single.savedAt, isNull);
    expect(current.savedIds, ['test-buddhist-calm']);
    expect(prefs.containsKey(MindCardStore.storageKey), isFalse);
    prepare(current, '감사');
    await current.saveCard();
    expect(prefs.getStringList(MindCardStore.legacyKey), legacy);
    final restored = session();
    expect(restored.savedIds, ['test-buddhist-care', 'test-buddhist-calm']);
    expect(restored.savedDetails.last.savedAt, isNull);
    expect(restored.savedDetail('christian-id'), isNull);
  });

  test(
      'Malformed/future/forged records fail closed and cannot overwrite existing bytes',
      () async {
    for (final payload in [
      '{broken',
      jsonEncode({'version': 99, 'cards': []}),
      jsonEncode({
        'version': 2,
        'cards': [
          {'scriptureId': 'test-buddhist-calm', 'savedAt': 'not-a-date'}
        ]
      }),
      jsonEncode({
        'version': 2,
        'cards': [
          {
            'scriptureId': 'test-buddhist-calm',
            'savedAt': null,
            'text': 'invented scripture'
          }
        ]
      }),
    ]) {
      await prefs.setString(MindCardStore.storageKey, payload);
      final current = session();
      expect(current.storageNotice, isNotNull);
      expect(current.savedDetails, isEmpty);
      prepare(current);
      await expectLater(current.saveCard(), throwsStateError);
      expect(prefs.getString(MindCardStore.storageKey), payload);
    }
  });

  test('False and thrown writes leave records unchanged and can be retried',
      () async {
    for (final throwsError in [false, true]) {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      var fail = true;
      final current = session(
          store: MindCardStore(prefs,
              clock: () => timestamp,
              writer: (key, value) async {
                if (fail) {
                  if (throwsError) throw StateError('private disk error');
                  return false;
                }
                return prefs.setString(key, value);
              }));
      prepare(current);
      await expectLater(current.saveCard(), throwsStateError);
      expect(current.savedDetails, isEmpty);
      expect(prefs.containsKey(MindCardStore.storageKey), isFalse);
      fail = false;
      await current.saveCard();
      expect(session().savedDetails, hasLength(1));
    }
  });

  test(
      'Concurrent saves reject safely; crisis during an in-flight save hides its result',
      () async {
    final gate = Completer<bool>();
    final current = session(
        store: MindCardStore(prefs, writer: (key, value) => gate.future));
    prepare(current);
    final pending = current.saveCard();
    await expectLater(current.saveCard(), throwsStateError);
    current.respond('죽고 싶어요');
    gate.complete(true);
    await pending;
    expect(current.savedDetails, isEmpty);
    expect(current.savedCards, isEmpty);
    expect(() => current.savedDetail('test-buddhist-calm'), throwsStateError);
    await expectLater(current.saveCard(), throwsStateError);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'Restored list and details show canonical source at 360px scale $scale',
        (tester) async {
      final current =
          session(store: MindCardStore(prefs, clock: () => timestamp));
      prepare(current);
      await current.saveCard();
      final restored = session();
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(BuddhistApp(session: restored));
      await tester.tap(find.text('저장·성장'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('카드 자세히 보기'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('카드 자세히 보기'));
      await tester.pumpAndSettle();
      expect(find.text('마음카드 상세'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('권리 상태: TEST_DATA_ONLY'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('권리 상태: TEST_DATA_ONLY'), findsOneWidget);
      expect(tester.takeException(), isNull);
      restored.respond('죽고 싶어요');
      await tester.tap(find.text('마음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장·성장'));
      await tester.pumpAndSettle();
      expect(find.text(current.card!.text), findsNothing);
      expect(find.text('카드 자세히 보기'), findsNothing);
    });
  }

  testWidgets('Save error is recoverable without exposing internal errors',
      (tester) async {
    var fail = true;
    final current = session(
        store: MindCardStore(prefs, writer: (key, value) async {
      if (fail) throw StateError('sensitive diagnostic');
      return prefs.setString(key, value);
    }));
    prepare(current);
    await tester.pumpWidget(BuddhistApp(session: current));
    Future<void> save() async {
      await tester.scrollUntilVisible(find.text('마음카드 저장'), 250,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('마음카드 저장'));
      await tester.pumpAndSettle();
    }

    await save();
    expect(current.savedIds, isEmpty);
    expect(find.text('저장하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.textContaining('sensitive diagnostic'), findsNothing);
    fail = false;
    await save();
    expect(current.savedIds, hasLength(1));
    expect(find.text('이 기기에 저장했습니다.'), findsOneWidget);
  });
}
