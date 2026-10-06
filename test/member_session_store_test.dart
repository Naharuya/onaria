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
}
