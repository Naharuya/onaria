import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/member_session_store.dart';

class MemoryPersistence implements MemberSessionPersistence {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

class FailingPersistence extends MemoryPersistence {
  bool failWrite = true, failDelete = false;
  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('fixture');
    await super.write(key, value);
  }

  @override
  Future<void> delete(String key) async {
    if (failDelete) throw StateError('fixture');
    await super.delete(key);
  }
}

void main() {
  const token = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ';

  test('member session is restored from secure persistence', () async {
    final persistence = MemoryPersistence();
    final first = MemberSessionStore.forTesting(persistence);
    first.set(token: token, expiresInSeconds: 3600);
    await Future<void>.delayed(Duration.zero);

    final restored = MemberSessionStore.forTesting(persistence);
    await restored.restore();
    expect(restored.token, token);
  });

  test('clear removes the persisted member session', () async {
    final persistence = MemoryPersistence();
    final store = MemberSessionStore.forTesting(persistence);
    store.set(token: token, expiresInSeconds: 3600);
    await Future<void>.delayed(Duration.zero);
    expect(persistence.values, isNotEmpty);

    store.clear();
    await Future<void>.delayed(Duration.zero);
    final restored = MemberSessionStore.forTesting(persistence);
    await restored.restore();
    expect(restored.token, isNull);
    expect(persistence.values, isEmpty);
  });

  test('immediate logout cannot be overwritten by queued login persistence',
      () async {
    final persistence = MemoryPersistence();
    final store = MemberSessionStore.forTesting(persistence);
    var notifications = 0;
    store.addListener(() => notifications++);
    store.set(token: token, expiresInSeconds: 3600);
    store.clear();
    final restored = MemberSessionStore.forTesting(persistence);
    await Future<void>.delayed(Duration.zero);
    await restored.restore();
    expect(restored.token, isNull);
    expect(persistence.values, isEmpty);
    expect(notifications, 2);
  });
  test(
      'storage failure is observable; cleanup retries without restoring an old session',
      () async {
    final p = FailingPersistence();
    final store = MemberSessionStore.forTesting(p);
    store.set(token: token, expiresInSeconds: 3600);
    expect(await store.flush(), false);
    expect(store.persistenceFailed, true);
    p.failWrite = false;
    store.set(token: token, expiresInSeconds: 3600);
    expect(await store.flush(), true);
    p.failDelete = true;
    store.clear();
    expect(await store.flush(), false);
    expect(store.token, isNull);
    expect(store.cleanupFailed, true);
    p.failDelete = false;
    store.clear();
    expect(await store.flush(), true);
    final restarted = MemberSessionStore.forTesting(p);
    await restarted.restore();
    expect(restarted.token, isNull);
  });
}
