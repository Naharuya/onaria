import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria_buddhist/session.dart';
import 'package:onaria_buddhist/local_conversation_client.dart';
import 'package:onaria_buddhist/mac_ai_client.dart';
import 'package:onaria_buddhist/dev_identity.dart';
import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:onaria_core/onaria_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAi implements AsyncConversationClient {
  final gate = Completer<Map<String, Object?>>();
  bool cancelled = false;
  bool throwOnCancel = false;
  @override
  Future<Map<String, Object?>> respond(LocalConversationRequest request) =>
      gate.future;
  @override
  void cancel() {
    cancelled = true;
    if (throwOnCancel) throw StateError('cancel failure');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BuddhistSession session;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = BuddhistSession(await BuddhistScriptureProvider.load(),
        await SharedPreferences.getInstance());
    session.startConversation(
        CheckInInput(emotion: EmotionType.anxiety, intensity: 5));
  });
  test('Crisis creates no AI client and remains sticky', () async {
    var factories = 0;
    await session.replyWithMacAi('죽고 싶어요', factory: () {
      factories++;
      return FakeAi();
    });
    await session.replyWithMacAi('괜찮아요', factory: () {
      factories++;
      return FakeAi();
    });
    expect(factories, 0);
    expect(session.isCrisis, true);
    expect(session.citations, isEmpty);
  });
  test('Validated AI template advances the same local contract', () async {
    final client = FakeAi();
    final pending = session.replyWithMacAi('할 일이 많아요', factory: () => client);
    expect(session.aiPending, true);
    client.gate.complete(
        {'profile': 'buddhist', 'phase': 'need', 'template': 'gentleNeed'});
    await pending;
    expect(session.phase, ConversationPhase.need);
    expect(session.message, contains('5/10'));
    expect(session.lastReplyUsedFallback, false);
    expect(client.cancelled, true);
  });
  test('Invented scripture or extra prose is rejected, never displayed',
      () async {
    final client = FakeAi();
    final pending = session.replyWithMacAi('쉼이 필요해요', factory: () => client);
    client.gate.complete({
      'profile': 'buddhist',
      'phase': 'need',
      'template': 'need',
      'text': '가짜 경전 장절 번역자'
    });
    await pending;
    expect(session.lastReplyUsedFallback, true);
    expect(session.message, isNot(contains('가짜')));
    expect(session.citations, isEmpty);
  });
  test('In-flight reply cannot overwrite a later crisis', () async {
    final client = FakeAi();
    final pending = session.replyWithMacAi('일이 많아요', factory: () => client);
    session.allowPendingInput('죽고 싶어요');
    final crisis = session.message;
    client.gate
        .complete({'profile': 'buddhist', 'phase': 'need', 'template': 'need'});
    await pending;
    expect(client.cancelled, true);
    expect(session.message, crisis);
  });
  test('Account switch and navigation cancellation discard late completion',
      () async {
    for (final switchAccount in [false, true]) {
      session.startConversation(
          CheckInInput(emotion: EmotionType.anxiety, intensity: 5));
      final client = FakeAi();
      final pending = session.replyWithMacAi('일이 많아요', factory: () => client);
      if (switchAccount) {
        session.switchDevIdentity(DevPrincipal.fixtureA);
      } else {
        session.cancelAiReply();
      }
      final previous = session.message;
      client.gate.complete(
          {'profile': 'buddhist', 'phase': 'need', 'template': 'need'});
      await pending;
      expect(session.message, previous);
      expect(client.cancelled, true);
    }
  });
  test('Transport failure falls back and allows a subsequent attempt',
      () async {
    final client = FakeAi();
    final pending = session.replyWithMacAi('일이 많아요', factory: () => client);
    client.gate.completeError(StateError('private transport detail'));
    await pending;
    expect(session.lastReplyUsedFallback, true);
    expect(session.aiPending, false);
    expect(session.message, isNot(contains('private')));
  });
  test('Throwing transport cancellation cannot interrupt crisis cleanup',
      () async {
    final client = FakeAi()..throwOnCancel = true;
    final pending = session.replyWithMacAi('일이 많아요', factory: () => client);
    session.allowPendingInput('죽고 싶어요');
    expect(session.isCrisis, true);
    expect(session.message, localCrisisMessage(session.riskLevel));
    expect(session.citations, isEmpty);
    client.gate
        .complete({'profile': 'buddhist', 'phase': 'need', 'template': 'need'});
    await pending;
    expect(session.message, localCrisisMessage(session.riskLevel));
  });
}
