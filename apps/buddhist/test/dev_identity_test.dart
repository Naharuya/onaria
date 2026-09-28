import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria_buddhist/dev_identity.dart';
import 'package:onaria_buddhist/mind_card_store.dart';
import 'package:onaria_buddhist/session.dart';
import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Scopes reject foreign issuers, stale generations and guest adapter bypass',
      () {
    final identity = DevIdentityProvider();
    final repository = DevCardRepository(identity);
    expect(() => repository.list(identity.current), throwsStateError);
    final a = identity.switchTo(DevPrincipal.fixtureA);
    repository.save(a, const MindCardReference('test-buddhist-calm', null));
    final b = identity.switchTo(DevPrincipal.fixtureB);
    expect(repository.list(b), isEmpty);
    expect(() => repository.list(a), throwsStateError);
    expect(() => repository.save(a, const MindCardReference('other', null)),
        throwsStateError);
    expect(
        () => repository.list(DevIdentityProvider().current), throwsStateError);
    expect(repository.list(identity.switchTo(DevPrincipal.fixtureA)),
        hasLength(1));
  });
  test(
      'Guest original bytes survive fixture switching; context and cards never cross owners',
      () async {
    SharedPreferences.setMockInitialValues({
      MindCardStore.legacyKey: ['test-buddhist-calm']
    });
    final prefs = await SharedPreferences.getInstance();
    final provider = await BuddhistScriptureProvider.load();
    final session = BuddhistSession(provider, prefs);
    expect(session.savedIds, ['test-buddhist-calm']);
    session.switchDevIdentity(DevPrincipal.fixtureA);
    expect(session.savedIds, isEmpty);
    session.respond('감사');
    session.makeCard(session.citations.first.id);
    await session.saveCard();
    session.switchDevIdentity(DevPrincipal.fixtureB);
    expect(session.savedIds, isEmpty);
    expect(session.card, isNull);
    expect(session.checkIn, isNull);
    session.switchDevIdentity(DevPrincipal.fixtureA);
    expect(session.savedIds, ['test-buddhist-care']);
    session.switchDevIdentity(DevPrincipal.guest);
    expect(session.savedIds, ['test-buddhist-calm']);
    expect(
        prefs.getStringList(MindCardStore.legacyKey), ['test-buddhist-calm']);
    expect(prefs.containsKey(MindCardStore.storageKey), isFalse);
    expect(
        session.switchDevIdentity(DevPrincipal.fixtureB,
            pendingInput: '죽고 싶어요'),
        isFalse);
    expect(session.switchDevIdentity(DevPrincipal.fixtureA), isFalse);
    expect(session.savedDetails, isEmpty);
    final restarted = BuddhistSession(provider, prefs);
    restarted.switchDevIdentity(DevPrincipal.fixtureA);
    expect(restarted.savedIds, isEmpty);
  });
  test('Late guest save cannot report success into a different identity',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final gate = Completer<bool>();
    final session = BuddhistSession(
        await BuddhistScriptureProvider.load(), prefs,
        cardStore: MindCardStore(prefs, writer: (key, value) => gate.future));
    session.respond('불안');
    session.makeCard(session.citations.first.id);
    final saving = session.saveCard();
    session.switchDevIdentity(DevPrincipal.fixtureA);
    gate.complete(true);
    await expectLater(saving, throwsStateError);
    expect(session.savedIds, isEmpty);
  });
}
