import 'package:flutter_test/flutter_test.dart';
import 'package:onaria_buddhist/session.dart';
import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:onaria_core/onaria_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'check_in_test.dart' show CountingProvider;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CountingProvider provider;
  late BuddhistSession session;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = CountingProvider(await BuddhistScriptureProvider.load());
    session = BuddhistSession(provider, await SharedPreferences.getInstance());
  });

  test('Cross-pack request clears previous content and never reaches provider',
      () {
    session.respond('불안');
    expect(session.citations, isNotEmpty);
    final previous = session.state;
    expect(
        () =>
            session.respond('불안', requestedProfile: ReligionProfile.christian),
        throwsStateError);
    expect(provider.searchCalls, 1);
    expect(session.state, same(previous));
    expect(session.message, isEmpty);
    expect(session.citations, isEmpty);
    expect(session.card, isNull);
    expect(session.state.profile, ReligionProfile.buddhist);
    session.respond('감사');
    expect(provider.searchCalls, 2);
    expect(session.state.turnCount, 2);
  });

  test('Crisis wins over cross-pack request and keeps retrieval at zero', () {
    session.respond('죽고 싶어요', requestedProfile: ReligionProfile.christian);
    expect(provider.searchCalls, 0);
    expect(session.state.phase, ConversationPhase.crisis);
    expect(session.message, localCrisisMessage(session.riskLevel));
    session.respond('불안');
    expect(provider.searchCalls, 0);
    expect(session.state.turnCount, 0);
    expect(() => session.makeCard('test-buddhist-calm'), throwsStateError);
    expect(session.saveCard(), throwsStateError);
  });

  test('No result retains empty citations with no invented source', () {
    session.respond('없는자료xyz');
    expect(session.message, noMatch);
    expect(session.citations, isEmpty);
    expect(session.state.turnCount, 1);
    expect(() => session.makeCard('invented'), throwsStateError);
  });
}
