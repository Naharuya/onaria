import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria_buddhist/main.dart';
import 'package:onaria_buddhist/session.dart';
import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:onaria_core/onaria_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlowProvider extends Fake implements BuddhistScriptureProvider {
  FlowProvider(this.delegate);
  final BuddhistScriptureProvider delegate;
  int searches = 0;
  bool fail = false;
  @override
  List<MockScripture> search(String query) {
    searches++;
    if (fail) throw StateError('private diagnostic must not reach UI');
    return delegate.search(query);
  }

  @override
  MockScripture? getById(String id) => delegate.getById(id);
  @override
  void assertCitation(Map<String, dynamic> candidate) =>
      delegate.assertCitation(candidate);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FlowProvider provider;
  late BuddhistSession session;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    provider = FlowProvider(await BuddhistScriptureProvider.load());
    session = BuddhistSession(provider, prefs);
  });
  void start([String query = '불안']) => session.startConversation(CheckInInput(
      emotion: EmotionType.anxiety, intensity: 6, customEmotion: query));
  void consent() {
    start();
    session.reply('일이 많았어요');
    session.reply('쉬고 싶어요');
  }

  test(
      'Consent gates retrieval; reflection and action produce a private local summary',
      () {
    start();
    expect(session.phase, ConversationPhase.situation);
    expect(provider.searches, 0);
    expect(() => session.chooseSource(true), throwsStateError);
    session.respond('일이 많았어요');
    expect(session.phase, ConversationPhase.need);
    expect(provider.searches, 0);
    session.reply('쉼');
    expect(session.phase, ConversationPhase.sourceOffer);
    expect(session.state.turnCount, 2);
    session.chooseSource(true);
    expect(provider.searches, 1);
    expect(session.phase, ConversationPhase.sourceReflection);
    session.makeCard(session.citations.single.id);
    session.reply('잠시 멈추고 싶어요');
    expect(session.phase, ConversationPhase.action);
    session.chooseAction(BuddhistSession.actions.first);
    expect(session.phase, ConversationPhase.summary);
    expect(session.message, contains('불안 · 6/10'));
    expect(session.message, contains('잠시 쉬기'));
    expect(session.state.turnCount, 3);
    expect(prefs.getKeys(), isEmpty);
    session.newCheckIn();
    expect(session.isGuided, isFalse);
    expect(session.card, isNull);
    expect(session.citations, isEmpty);
  });

  test('Decline never searches; no results never fabricate a source', () {
    consent();
    session.chooseSource(false);
    expect(provider.searches, 0);
    expect(session.phase, ConversationPhase.action);
    session.chooseAction(BuddhistSession.actions.last);
    expect(session.citations, isEmpty);
    start('없는자료xyz');
    session.reply('일');
    session.reply('쉼');
    session.chooseSource(true);
    expect(session.message, contains(noMatch));
    expect(session.citations, isEmpty);
    expect(session.phase, ConversationPhase.action);
    expect(() => session.makeCard('invented'), throwsStateError);
  });

  test(
      'Provider failure stays at consent with safe retry and no internal error',
      () {
    consent();
    provider.fail = true;
    session.chooseSource(true);
    expect(session.phase, ConversationPhase.sourceOffer);
    expect(session.citations, isEmpty);
    expect(session.message, isNot(contains('private diagnostic')));
    provider.fail = false;
    session.chooseSource(true);
    expect(session.citations, isNotEmpty);
    expect(provider.searches, 2);
  });

  test(
      'Invalid input, transitions and cross-pack requests do not advance or retrieve',
      () {
    start();
    for (final value in ['', '  ', '가' * 2001]) {
      expect(() => session.reply(value), throwsArgumentError);
    }
    expect(() => session.chooseAction('arbitrary'), throwsStateError);
    expect(
        () => session.reply('불안', requestedProfile: ReligionProfile.christian),
        throwsStateError);
    expect(session.state.turnCount, 0);
    expect(provider.searches, 0);
    session.reply('일');
    session.reply('쉼');
    session.chooseSource(false);
    expect(() => session.chooseAction('arbitrary'), throwsArgumentError);
    expect(session.phase, ConversationPhase.action);
  });

  test('All six phases apply the full Safety corpus before any downstream work',
      () {
    final rows = jsonDecode(
            File('../../backend_contract/safety_cases.json').readAsStringSync())
        as List;
    for (final phase in [
      ConversationPhase.situation,
      ConversationPhase.need,
      ConversationPhase.sourceOffer,
      ConversationPhase.sourceReflection,
      ConversationPhase.action,
      ConversationPhase.summary
    ]) {
      for (final row in rows) {
        session = BuddhistSession(provider, prefs);
        start();
        if (phase != ConversationPhase.situation) session.reply('일');
        if (phase != ConversationPhase.situation &&
            phase != ConversationPhase.need) {
          session.reply('쉼');
        }
        if ([
          ConversationPhase.sourceReflection,
          ConversationPhase.action,
          ConversationPhase.summary
        ].contains(phase)) {
          session.chooseSource(true);
        }
        if ([ConversationPhase.action, ConversationPhase.summary]
            .contains(phase)) {
          session.reply('쉬고 싶어요');
        }
        if (phase == ConversationPhase.summary) {
          session.chooseAction(BuddhistSession.actions.first);
        }
        final before = provider.searches;
        try {
          session.reply(row['text'] as String);
        } on StateError {/* button-only safe phases */}
        expect(session.riskLevel, row['level'],
            reason: '${phase.name}/${row['id']}');
        expect(provider.searches, before);
        if (session.isCrisis) {
          expect(session.phase, ConversationPhase.crisis);
          expect(session.message, localCrisisMessage(session.riskLevel));
          expect(session.citations, isEmpty);
          expect(session.card, isNull);
          expect(session.savedCards, isEmpty);
          session.chooseSource(true);
          expect(provider.searches, before);
          start();
          expect(session.isCrisis, isTrue);
        }
      }
    }
  });

  test('Unsent crisis text is intercepted on consent and action buttons', () {
    consent();
    session.chooseSource(true, pendingInput: '죽고 싶어요');
    expect(session.isCrisis, isTrue);
    expect(provider.searches, 0);
    session = BuddhistSession(provider, prefs);
    consent();
    session.chooseSource(false);
    session.chooseAction(BuddhistSession.actions.first, pendingInput: '죽고 싶어요');
    expect(session.isCrisis, isTrue);
    expect(session.selectedAction, isNull);
  });

  for (final control in ['테스트 자료 보기', '마음카드 만들기', '마음카드 저장', '저장·성장']) {
    testWidgets('Pending crisis blocks $control before content or storage',
        (tester) async {
      consent();
      if (control != '테스트 자료 보기') session.chooseSource(true);
      if (control == '마음카드 저장') session.makeCard(session.citations.single.id);
      final before = provider.searches;
      await tester.pumpWidget(BuddhistApp(session: session));
      await tester.enterText(find.byType(TextField), '죽고 싶어요');
      await tester.scrollUntilVisible(find.text(control), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(control));
      await tester.pumpAndSettle();
      expect(session.isCrisis, isTrue);
      expect(provider.searches, before);
      expect(session.citations, isEmpty);
      expect(session.card, isNull);
      expect(session.savedIds, isEmpty);
      expect(prefs.getKeys(), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
        '360px guided UI completes reflection and action at scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      Future<void> tap(String label) async {
        await tester.scrollUntilVisible(find.text(label), 180,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(BuddhistApp(session: session));
      await tap('마음 살펴보기');
      expect(provider.searches, 0);
      for (final text in ['일이 많았어요', '쉼']) {
        await tester.enterText(find.byType(TextField), text);
        await tap('이야기 보내기');
      }
      await tap('테스트 자료 보기');
      expect(provider.searches, 1);
      await tester.enterText(find.byType(TextField), '돌아보고 싶어요');
      await tap('이야기 보내기');
      await tap('잠시 쉬기');
      expect(session.phase, ConversationPhase.summary);
      await tap('새 마음 살펴보기');
      expect(find.byType(ChoiceChip), findsNWidgets(16));
    });
  }
}
