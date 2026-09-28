import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria_buddhist/local_conversation_client.dart';
import 'package:onaria_buddhist/session.dart';
import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:onaria_core/onaria_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubClient implements LocalConversationClient {
  StubClient(this.handler);
  final Map<String, Object?> Function(LocalConversationRequest) handler;
  final List<LocalConversationRequest> requests = [];
  @override
  Map<String, Object?> respond(LocalConversationRequest request) {
    requests.add(request);
    return handler(request);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BuddhistScriptureProvider provider;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    provider = await BuddhistScriptureProvider.load();
  });
  void start(BuddhistSession session, {int intensity = 5}) =>
      session.startConversation(
          CheckInInput(emotion: EmotionType.anxiety, intensity: intensity));

  test(
      'Trusted emotion/intensity and immutable bounded context reach the local client only',
      () {
    final client = StubClient(const MockConversationClient().respond);
    final session =
        BuddhistSession(provider, prefs, clientFactory: () => client);
    start(session, intensity: 9);
    session.reply('잠시 쉬고 싶어요');
    expect(session.message, contains('9/10'));
    session.reply('이해받고 싶어요');
    expect(session.message, contains('쉼에 관해'));
    expect(client.requests.last.previousInputs, ['잠시 쉬고 싶어요']);
    expect(() => client.requests.last.previousInputs.add('edited'),
        throwsUnsupportedError);
    session.chooseSource(true);
    session.reply('돌아보고 싶어요');
    expect(client.requests.last.previousInputs, hasLength(2));
    expect(client.requests.last.emotion, EmotionType.anxiety);
    expect(client.requests.last.profile, ReligionProfile.buddhist);
    expect(prefs.getKeys(), isEmpty);
    session.chooseAction(BuddhistSession.actions.first);
    session.newCheckIn();
    start(session);
    session.reply('다시 시작');
    expect(client.requests.last.previousInputs, isEmpty);
  });

  test('All Safety fixtures bypass client construction and invocation', () {
    final rows = jsonDecode(
            File('../../backend_contract/safety_cases.json').readAsStringSync())
        as List;
    for (final row in rows) {
      var factories = 0;
      final client = StubClient(const MockConversationClient().respond);
      final session = BuddhistSession(provider, prefs, clientFactory: () {
        factories++;
        return client;
      });
      start(session);
      session.reply(row['text'] as String);
      expect(session.riskLevel, row['level']);
      expect(factories, row['level'] == 0 ? 1 : 0);
      if (session.isCrisis) {
        expect(client.requests, isEmpty);
        expect(session.message, localCrisisMessage(session.riskLevel));
        session.reply('평범한 말');
        expect(client.requests, isEmpty);
      }
    }
  });

  test(
      'Invalid input, wrong phase and cross-pack requests never construct client',
      () {
    var factories = 0;
    final session = BuddhistSession(provider, prefs, clientFactory: () {
      factories++;
      return const MockConversationClient();
    });
    start(session);
    expect(() => session.reply(' '), throwsArgumentError);
    expect(() => session.reply('가' * 2001), throwsArgumentError);
    expect(
        () =>
            session.reply('보통 말', requestedProfile: ReligionProfile.christian),
        throwsStateError);
    expect(factories, 0);
  });

  test(
      'Fabricated prose, references, wrong profile/phase and unknown templates fall back safely',
      () {
    for (final response in <Map<String, Object?>>[
      {'profile': 'christian', 'phase': 'need', 'template': 'need'},
      {'profile': 'buddhist', 'phase': 'summary', 'template': 'need'},
      {
        'profile': 'buddhist',
        'phase': 'need',
        'template': 'invented scripture'
      },
      {
        'profile': 'buddhist',
        'phase': 'need',
        'template': 'need',
        'text': 'invented scripture'
      },
      {
        'profile': 'buddhist',
        'phase': 'need',
        'template': 'need',
        'source': 'invented scripture'
      },
      {},
    ]) {
      final session = BuddhistSession(provider, prefs,
          clientFactory: () => StubClient((_) => response));
      start(session);
      session.reply('일이 많았어요');
      expect(session.lastReplyUsedFallback, isTrue);
      expect(session.phase, ConversationPhase.need);
      expect(session.message, isNot(contains('invented')));
      expect(session.citations, isEmpty);
      expect(session.card, isNull);
    }
  });

  test('Factory/client exceptions use safe fallback and a later reply recovers',
      () {
    var fail = true;
    final client = StubClient((request) {
      if (fail) throw StateError('private diagnostic');
      return const MockConversationClient().respond(request);
    });
    final session =
        BuddhistSession(provider, prefs, clientFactory: () => client);
    start(session);
    session.reply('일이 많아요');
    expect(session.lastReplyUsedFallback, isTrue);
    expect(session.message, isNot(contains('private diagnostic')));
    fail = false;
    session.reply('쉼');
    expect(session.lastReplyUsedFallback, isFalse);
    expect(session.phase, ConversationPhase.sourceOffer);
    final broken = BuddhistSession(provider, prefs,
        clientFactory: () => throw StateError('secret'));
    start(broken);
    broken.reply('보통 말');
    expect(broken.lastReplyUsedFallback, isTrue);
    expect(broken.phase, ConversationPhase.need);
  });

  test('Reentrant crisis cannot be overwritten by a returning client response',
      () {
    late BuddhistSession session;
    session = BuddhistSession(provider, prefs,
        clientFactory: () => StubClient((request) {
              session.reply('죽고 싶어요');
              return const MockConversationClient().respond(request);
            }));
    start(session);
    session.reply('보통 말');
    expect(session.isCrisis, isTrue);
    expect(session.phase, ConversationPhase.crisis);
    expect(session.message, localCrisisMessage(session.riskLevel));
    expect(session.citations, isEmpty);
  });
}
