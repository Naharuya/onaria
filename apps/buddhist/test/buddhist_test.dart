import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria_buddhist/main.dart';
import 'package:onaria_buddhist/session.dart';
import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BuddhistSession session;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = BuddhistSession(await BuddhistScriptureProvider.load(),
        await SharedPreferences.getInstance());
  });

  test(
      'Shared corpus Safety parity, false positives and no retrieval for crisis',
      () {
    final cases = jsonDecode(
            File('../../backend_contract/safety_cases.json').readAsStringSync())
        as List;
    for (final row in cases) {
      final current = BuddhistSession(session.provider, session.preferences);
      current.respond(row['text'] as String);
      expect(current.riskLevel, row['level'], reason: row['id'] as String);
      if (current.isCrisis) {
        expect(current.citations, isEmpty);
        expect(() => current.makeCard('test-buddhist-calm'), throwsStateError);
        current.respond('불안');
        expect(current.isCrisis, isTrue);
      }
    }
  });

  test(
      'Provider covers twelve themes, metadata and rejects fabricated citations',
      () {
    final provider = session.provider;
    for (final theme in [
      '마음',
      '고통',
      '불안',
      '분노',
      '관계',
      '상실',
      '집착',
      '자비',
      '감사',
      '무상',
      '마음챙김',
      '평정'
    ]) {
      expect(provider.searchByTheme(theme), isNotEmpty);
    }
    expect(provider.searchByEmotion('불안'), isNotEmpty);
    expect(provider.getSource('missing'), isNull);
    expect(provider.getLicense('missing'), isNull);
    expect(provider.search('존재하지않는자료'), isEmpty);
    final record = provider.getRandomReflection()!;
    provider.assertCitation(record.metadata);
    for (final key in [
      'id',
      'title',
      'text',
      'translator',
      'source',
      'chapter',
      'section',
      'license',
      'copyright_status'
    ]) {
      expect(
          () => provider.assertCitation({...record.metadata, key: 'invented'}),
          throwsStateError);
    }
    expect(
        () => provider
            .assertCitation({...record.metadata, 'extra': 'unreviewed'}),
        throwsStateError);
    expect(() => record.metadata['text'] = 'edited', throwsUnsupportedError);
  });

  test(
      'No match never generates a quotation; persisted IDs exclude blocked or foreign content',
      () async {
    session.respond('성경 요한복음 홍길동 999장 인용해');
    expect(session.message, noMatch);
    expect(session.citations, isEmpty);
    await session.preferences.setStringList(BuddhistSession.storageKey,
        ['external-intake-disabled', 'christian-id', 'test-buddhist-calm']);
    final restored = BuddhistSession(session.provider, session.preferences);
    expect(restored.savedCards.map((c) => c.id), ['test-buddhist-calm']);
  });

  test(
      'Card save and reload preserve provider content; crisis hides prior saved cards',
      () async {
    session.respond('불안');
    session.makeCard(session.citations.single.id);
    await session.saveCard();
    await session.saveCard();
    expect(session.savedIds.length, 1);
    final restored = BuddhistSession(session.provider, session.preferences);
    expect(restored.savedCards.single.text, session.card!.text);
    session.respond('죽고 싶어요');
    expect(session.card, isNull);
    expect(session.savedCards, isEmpty);
    expect(session.saveCard(), throwsStateError);
  });

  testWidgets('Check-in → reflection → mind card → save → growth → Admin',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BuddhistApp(session: session));
    await tester.enterText(find.byType(TextField), '불안');
    await tester.ensureVisible(find.text('마음 살펴보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마음 살펴보기'));
    await tester.pumpAndSettle();
    for (final answer in ['오늘 일이 많았어요', '잠시 쉬고 싶어요']) {
      await tester.enterText(find.byType(TextField), answer);
      await tester.ensureVisible(find.text('이야기 보내기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이야기 보내기'));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('테스트 자료 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('테스트 자료 보기'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('마음카드 만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마음카드 만들기'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('마음카드 저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마음카드 저장'));
    await tester.pumpAndSettle();
    expect(session.savedIds.length, 1);
    await tester.tap(find.text('저장·성장'));
    await tester.pumpAndSettle();
    expect(find.text('저장한 테스트 마음카드 1개'), findsOneWidget);
    await tester.tap(find.text('개발 상태').first);
    await tester.pumpAndSettle();
    expect(find.text('외부 자료: BLOCKED_EXTERNAL_REVIEW'), findsOneWidget);
    expect(find.textContaining('성경'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Crisis has local help and no citation or card even after a neutral turn',
      (tester) async {
    await tester.pumpWidget(BuddhistApp(session: session));
    await tester.enterText(find.byType(TextField), '죽고 싶어요');
    await tester.ensureVisible(find.text('마음 살펴보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마음 살펴보기'));
    await tester.pumpAndSettle();
    expect(session.message, contains('109'));
    expect(find.text('마음카드 만들기'), findsNothing);
    await tester.enterText(find.byType(TextField), '불안');
    await tester.ensureVisible(find.text('마음 살펴보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마음 살펴보기'));
    await tester.pumpAndSettle();
    expect(session.message, contains('109'));
    expect(tester.takeException(), isNull);
  });
}
