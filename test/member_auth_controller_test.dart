import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/app/member_auth_controller.dart';
import 'package:onaria/app/member_session_store.dart';
import 'package:onaria/src/api/provider_auth_api_client.dart';

class AuthMemoryPersistence implements MemberSessionPersistence {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

class FailingAuthPersistence extends AuthMemoryPersistence {
  bool failing = true;
  @override
  Future<String?> read(String key) async {
    if (failing) throw StateError('secure storage unavailable');
    return super.read(key);
  }
}

void main() {
  test('account timeout ends checking, preserves session and retry recovers',
      () async {
    final store = MemberSessionStore.forTesting(AuthMemoryPersistence());
    store.set(token: 'A' * 43, expiresInSeconds: 3600);
    var responding = false;
    final pending = Completer<http.Response>();
    final auth = MemberAuthController(
      sessions: store,
      clientFactory: () => ProviderAuthApiClient(
        baseUrl: Uri.parse('https://api.onaria.ai.kr'),
        timeout: const Duration(milliseconds: 20),
        httpClient: MockClient((_) async => responding
            ? http.Response(
                '{"providers":["naver"],"currentProvider":"naver"}', 200)
            : pending.future),
      ),
    );
    addTearDown(auth.dispose);
    addTearDown(store.dispose);
    final check = auth.refresh();
    expect(auth.label, '확인 중');
    await check;
    expect(auth.label, '로그인 상태 확인 불가');
    expect(store.token, 'A' * 43);
    responding = true;
    await auth.retry();
    expect(auth.label, '로그인됨 · 네이버');
    expect(store.token, 'A' * 43);
    pending.complete(http.Response('{}', 503));
  });
  MemberAuthController controller(MemberSessionStore store,
      Future<http.Response> Function(http.Request) handler) {
    final value = MemberAuthController(
      sessions: store,
      signOutNaver: () async {},
      clientFactory: () => ProviderAuthApiClient(
          baseUrl: Uri.parse('https://api.onaria.ai.kr'),
          httpClient: MockClient(handler)),
    );
    addTearDown(value.dispose);
    addTearDown(store.dispose);
    return value;
  }

  for (final provider in ['naver', 'google', 'apple', 'kakao']) {
    test('verified session reports current provider $provider', () async {
      final store = MemberSessionStore.forTesting(AuthMemoryPersistence());
      store.set(token: 'A' * 43, expiresInSeconds: 3600);
      final auth = controller(
          store,
          (_) async => http.Response(
              jsonEncode({
                'providers': [provider],
                'currentProvider': provider,
              }),
              200));
      await auth.refresh();
      expect(auth.state, MemberAuthState.signedIn);
      expect(auth.provider, provider);
      expect(
          auth.label,
          {
            'naver': '로그인됨 · 네이버',
            'google': '로그인됨 · Google',
            'apple': '로그인됨 · Apple',
            'kakao': '로그인됨 · 카카오',
          }[provider]);
    });
  }

  test('401 clears only stale session; temporary failure preserves it',
      () async {
    final persistence = AuthMemoryPersistence();
    final store = MemberSessionStore.forTesting(persistence);
    store.set(token: 'A' * 43, expiresInSeconds: 3600);
    var status = 503;
    final auth = controller(store, (_) async => http.Response('{}', status));
    await auth.refresh();
    expect(auth.state, MemberAuthState.unavailable);
    expect(store.token, 'A' * 43);
    status = 401;
    await auth.refresh();
    expect(auth.state, MemberAuthState.signedOut);
    expect(store.token, isNull);
  });

  test('late 401 from an older session cannot erase a new login', () async {
    final store = MemberSessionStore.forTesting(AuthMemoryPersistence());
    store.set(token: 'A' * 43, expiresInSeconds: 3600);
    final pending = Completer<http.Response>();
    final auth = controller(store, (request) async {
      if (request.headers['X-Onaria-Member-Session'] == 'A' * 43) {
        return pending.future;
      }
      return http.Response(
          '{"providers":["google"],"currentProvider":"google"}', 200);
    });
    final old = auth.refresh();
    expect(auth.label, '확인 중');
    store.set(token: 'B' * 43, expiresInSeconds: 3600);
    await Future<void>.delayed(Duration.zero);
    pending.complete(http.Response('{}', 401));
    await old;
    expect(store.token, 'B' * 43);
    expect(auth.label, '로그인됨 · Google');
  });

  test('failed logout retains session; successful logout removes it', () async {
    final store = MemberSessionStore.forTesting(AuthMemoryPersistence());
    store.set(token: 'A' * 43, expiresInSeconds: 3600);
    var logoutStatus = 503;
    final auth = controller(
        store,
        (request) async => request.method == 'DELETE'
            ? http.Response('{}', logoutStatus)
            : http.Response(
                '{"providers":["naver"],"currentProvider":"naver"}', 200));
    await auth.refresh();
    await expectLater(auth.logout(), throwsA(isA<ProviderAuthApiException>()));
    expect(store.token, isNotNull);
    logoutStatus = 204;
    expect(await auth.logout(), isTrue);
    expect(store.token, isNull);
    expect(auth.label, '로그인하지 않음');
  });

  test('secure storage failure is unknown until restoration retry succeeds',
      () async {
    final persistence = FailingAuthPersistence();
    final store = MemberSessionStore.forTesting(persistence);
    store.set(token: 'A' * 43, expiresInSeconds: 3600);
    await store.restore();
    final auth = controller(
        store,
        (_) async => http.Response(
            '{"providers":["apple"],"currentProvider":"apple"}', 200));
    await auth.refresh();
    expect(auth.state, MemberAuthState.unavailable);
    persistence.failing = false;
    await auth.retry();
    expect(auth.label, '로그인됨 · Apple');
  });
}
