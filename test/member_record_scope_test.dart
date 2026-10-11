import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/member_record_scope.dart';
import 'package:onaria/app/mind_card_store.dart';
import 'package:onaria/app/conversation_draft.dart';
import 'package:onaria/app/legacy_record_import.dart';
import 'package:onaria/app/member_record_cleanup.dart';
import 'package:onaria/engagement/storage.dart';
import 'package:onaria/onaria.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

MindCardRecord card(String id) => MindCardRecord(
    id: id,
    createdAt: DateTime.utc(2026),
    title: 'fixture',
    dateLabel: 'fixture',
    emotion: 'fixture',
    intensity: 1,
    verseReference: 'fixture',
    verseText: 'fixture',
    reflectionQuestion: 'fixture',
    action: 'fixture',
    closingMessage: 'fixture');

class DelayedPreferences extends SharedPreferencesAsync {
  final gate = Completer<void>();
  @override
  Future<List<String>?> getStringList(String key) async {
    await gate.future;
    return super.getStringList(key);
  }
}

class InterruptedPreferences extends SharedPreferencesAsync {
  final failure = [true];
  bool get fail => failure[0];
  set fail(bool value) {
    failure[0] = value;
  }

  @override
  Future<void> setString(String key, String value) {
    if (fail &&
        key.contains('member.1') &&
        key.endsWith('onaria.unsent_draft.v1'))
      return Future.error(StateError('fixture storage full'));
    return super.setString(key, value);
  }
}

void main() {
  final scope = MemberRecordScope.instance;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    scope.signedOut();
  });
  tearDown(() {
    scope.signedOut();
    SharedPreferencesAsyncPlatform.instance = null;
  });
  test(
      'A B A, logout and guest are separate; stale stores cannot read or write',
      () async {
    scope.verified(1);
    final a = MindCardStore();
    await a.save(card('same-id'));
    scope.verified(2);
    final b = MindCardStore();
    expect(await b.getAll(), isEmpty);
    await b.save(card('b'));
    await expectLater(a.getAll(), throwsStateError);
    await expectLater(a.save(card('late')), throwsStateError);
    scope.signedOut();
    expect(await MindCardStore().getAll(), isEmpty);
    scope.verified(1);
    expect((await MindCardStore().getAll()).single.id, 'same-id');
    scope.verified(2);
    expect((await MindCardStore().getAll()).single.id, 'b');
  });
  test('late load rejects its old generation instead of leaking record to B',
      () async {
    scope.verified(1);
    await MindCardStore().save(card('private-a'));
    final delayed = DelayedPreferences();
    final pending = MindCardStore(preferences: delayed).getAll();
    scope.verified(2);
    delayed.gate.complete();
    await expectLater(pending, throwsStateError);
    expect(await MindCardStore().getAll(), isEmpty);
  });
  test(
      'draft and engagement storage separate members; unverified access fails closed',
      () async {
    scope.verified(1);
    await const ConversationDraft(
            text: 'fixture', emotion: EmotionType.joy, intensity: 1)
        .save();
    final a = PreferencesEngagementStorage();
    await a.write('fixture', 'private-a');
    scope.verified(2);
    expect(await ConversationDraft.load(), isNull);
    expect(await PreferencesEngagementStorage().read('fixture'), isNull);
    await expectLater(a.read('fixture'), throwsStateError);
    scope.lock();
    await expectLater(MindCardStore().getAll(), throwsStateError);
  });
  test(
      'legacy import preserves originals, order and damaged records, is idempotent and forbids other owner',
      () async {
    final p = SharedPreferencesAsync();
    final raw = [
      jsonEncode(card('first').toJson()),
      'damaged fixture',
      jsonEncode(card('last').toJson())
    ];
    await p.setStringList('soul_bible.mind_cards.v1', raw);
    scope.verified(1);
    expect(await MindCardStore().getAll(), isEmpty);
    final importer = LegacyRecordImport();
    await expectLater(
        importer.copyToCurrentMember(deviceOwnershipVerified: false),
        throwsStateError);
    await importer.copyToCurrentMember(deviceOwnershipVerified: true);
    await importer.copyToCurrentMember(deviceOwnershipVerified: true);
    expect(
        (await MindCardStore().getAll()).map((c) => c.id), ['first', 'last']);
    expect(await p.getStringList('soul_bible.mind_cards.v1'), raw);
    scope.verified(2);
    await expectLater(
        importer.copyToCurrentMember(deviceOwnershipVerified: true),
        throwsStateError);
    expect(await MindCardStore().getAll(), isEmpty);
  });
  test(
      'interrupted copy resumes after restart without deleting original or overwriting another target',
      () async {
    final p = InterruptedPreferences();
    await p.setStringList(
        'soul_bible.mind_cards.v1', [jsonEncode(card('original').toJson())]);
    await p.setString('onaria.unsent_draft.v1', 'fixture');
    scope.verified(1);
    await expectLater(
        LegacyRecordImport(preferences: p)
            .copyToCurrentMember(deviceOwnershipVerified: true),
        throwsStateError);
    expect(await p.getStringList('soul_bible.mind_cards.v1'), hasLength(1));
    p.fail = false;
    await LegacyRecordImport(preferences: p)
        .copyToCurrentMember(deviceOwnershipVerified: true);
    expect((await MindCardStore().getAll()).single.id, 'original');
  });
  test(
      'account deletion cleanup touches only the captured member, not B or legacy',
      () async {
    final p = SharedPreferencesAsync();
    await p.setStringList('soul_bible.mind_cards.v1', ['legacy']);
    scope.verified(2);
    await MindCardStore().save(card('b'));
    scope.verified(1);
    await MindCardStore().save(card('a'));
    await MindCardStore().deleteAll();
    scope.verified(2);
    expect((await MindCardStore().getAll()).single.id, 'b');
    expect(await p.getStringList('soul_bible.mind_cards.v1'), ['legacy']);
  });
  test(
      'durable local cleanup ignores unconfirmed response and survives restart',
      () async {
    final p = SharedPreferencesAsync();
    scope.verified(1);
    await MindCardStore().save(card('a'));
    scope.verified(2);
    await MindCardStore().save(card('b'));
    expect(await MemberRecordCleanup(preferences: p).retry(1), false);
    scope.verified(1);
    expect((await MindCardStore().getAll()).single.id, 'a');
    await MemberRecordCleanup(preferences: p).markServerDeleted(1);
    await MemberRecordCleanup(preferences: p).retryConfirmed();
    expect(await MindCardStore().getAll(), isEmpty);
    scope.verified(2);
    expect((await MindCardStore().getAll()).single.id, 'b');
  });
}
