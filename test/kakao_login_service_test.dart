import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/src/auth/kakao_login_service.dart';
import 'package:onaria/src/api/provider_auth_api_client.dart';

class DelayedKakaoGateway implements KakaoLoginGateway {
  final pending = Completer<String?>();
  int calls = 0;
  bool delayed = true;
  bool failDiscovery = false;
  @override
  Future<bool> isTalkInstalled() async {
    if (failDiscovery) throw StateError('synthetic-private-payload');
    return false;
  }

  @override
  Future<String?> loginWithTalk({required String nonce}) =>
      throw UnimplementedError();
  @override
  Future<String?> loginWithAccount({required String nonce}) {
    calls++;
    return delayed ? pending.future : Future.value('fresh-token');
  }
}

void main() {
  KakaoLoginService service(DelayedKakaoGateway gateway) => KakaoLoginService(
        api: ProviderAuthApiClient(
            baseUrl: Uri.parse('https://example.invalid')),
        gateway: gateway,
        enabled: true,
      );

  testWidgets('timeout blocks duplicate native UI until late callback settles',
      (tester) async {
    final gateway = DelayedKakaoGateway();
    final first = expectLater(
        service(gateway).authenticate(),
        throwsA(isA<KakaoLoginException>()
            .having((e) => e.message, 'message', contains('지연'))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 91));
    await first;
    await expectLater(
        service(gateway).authenticate(),
        throwsA(isA<KakaoLoginException>()
            .having((e) => e.message, 'message', contains('진행 중'))));
    expect(gateway.calls, 1);
    gateway.pending.complete('late-token');
    await tester.pump();
    gateway.delayed = false;
    final fresh = await service(gateway).authenticate();
    expect(fresh.idToken, 'fresh-token');
    expect(fresh.nonce.length, 64);
    expect(gateway.calls, 2);
  });

  test('discovery failure is sanitized and allows retry', () async {
    final gateway = DelayedKakaoGateway()..failDiscovery = true;
    await expectLater(
        service(gateway).authenticate(),
        throwsA(isA<KakaoLoginException>()
            .having((e) => e.message, 'message', isNot(contains('private')))));
    gateway.failDiscovery = false;
    gateway.delayed = false;
    expect((await service(gateway).authenticate()).idToken, 'fresh-token');
  });
}
