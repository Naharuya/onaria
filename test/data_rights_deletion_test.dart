import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:onaria/app/member_record_scope.dart';
import 'package:onaria/app/record_preferences.dart';

class DelayedWrite extends SharedPreferencesAsync {
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> setString(String key, String value) async {
    entered.complete();
    await release.future;
    await super.setString(key, value);
  }
}

class FailingRemove extends SharedPreferencesAsync {
  @override
  Future<void> remove(String key) => Future.error(StateError('fixture failed'));
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
      'full local deletion preserves other owners, guest, unowned legacy and account metadata',
      () async {
    final raw = SharedPreferencesAsync();
    scope.verified(1);
    final prefix = scope.capture().key('');
    await RecordPreferences().setString(prefix + 'card', 'private');
    await raw.setString('session-token-fixture', 'not-a-record');
    await raw.setString('unowned-legacy', 'keep');
    scope.verified(2);
    final other = scope.capture().key('card');
    await RecordPreferences().setString(other, 'other');
    scope.signedOut();
    final guest = scope.capture().key('card');
    await RecordPreferences().setString(guest, 'guest');
    scope.verified(1);
    final stale = RecordPreferences();
    await RecordPreferences.deleteCurrent();
    expect((await raw.getKeys()).where((k) => k.startsWith(prefix)), isEmpty);
    expect(await raw.getString(other), 'other');
    expect(await raw.getString(guest), 'guest');
    expect(await raw.getString('unowned-legacy'), 'keep');
    expect(await raw.getString('session-token-fixture'), 'not-a-record');
    await expectLater(
        stale.setString(prefix + 'resurrect', 'bad'), throwsStateError);
    expect(scope.memberId, 1);
    expect(scope.locked, false);
  });
  test('deletion waits for an OS write already in flight then removes it',
      () async {
    scope.verified(1);
    final key = scope.capture().key('card');
    final delayed = DelayedWrite();
    final pending =
        RecordPreferences(preferences: delayed).setString(key, 'private');
    await delayed.entered.future;
    var complete = false;
    final deletion = RecordPreferences.deleteCurrent().then((_) {
      complete = true;
    });
    await Future<void>.delayed(Duration.zero);
    expect(complete, false);
    expect(scope.locked, true);
    delayed.release.complete();
    await pending;
    await deletion;
    expect(await SharedPreferencesAsync().getString(key), isNull);
  });
  test(
      'failed deletion reports failure, unlocks for retry and never clears another owner',
      () async {
    scope.verified(1);
    final key = scope.capture().key('card');
    await RecordPreferences().setString(key, 'private');
    await expectLater(
        RecordPreferences.deleteCurrent(preferences: FailingRemove()),
        throwsStateError);
    expect(scope.locked, false);
    expect(await SharedPreferencesAsync().getString(key), 'private');
    await RecordPreferences.deleteCurrent();
    expect(await SharedPreferencesAsync().getString(key), isNull);
  });
  test(
      'account switch during deletion rejects old transaction and preserves new account writes',
      () async {
    scope.verified(1);
    final key = scope.capture().key('card');
    final delayed = DelayedWrite();
    final pending =
        RecordPreferences(preferences: delayed).setString(key, 'private');
    await delayed.entered.future;
    final deletion = RecordPreferences.deleteCurrent();
    final checked = expectLater(deletion, throwsStateError);
    scope.verified(2);
    final other = scope.capture().key('card');
    final write = RecordPreferences().setString(other, 'other');
    delayed.release.complete();
    await pending;
    await checked;
    await write;
    expect(scope.memberId, 2);
    expect(await SharedPreferencesAsync().getString(other), 'other');
  });
}
