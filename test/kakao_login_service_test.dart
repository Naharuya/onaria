import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/app/member_session_store.dart';
import 'package:onaria/src/api/provider_auth_api_client.dart';
import 'package:onaria/src/auth/kakao_login_service.dart';

class FakeKakaoGateway implements KakaoLoginGateway {
  FakeKakaoGateway(
      {this.talkInstalled = true, this.talkToken, this.accountToken});
  final bool talkInstalled;
  final String? talkToken;
  final String? accountToken;
  String? talkNonce;
  String? accountNonce;
  int talkCalls = 0;
  int accountCalls = 0;
  @override
  Future<bool> isTalkInstalled() async => talkInstalled;
  @override
  Future<String?> loginWithTalk({required String nonce}) async {
    talkCalls++;
    talkNonce = nonce;
    return talkToken;
  }

  @override
  Future<String?> loginWithAccount({required String nonce}) async {
    accountCalls++;
    accountNonce = nonce;
    return accountToken;
  }
}

void main() {
  setUp(() => MemberSessionStore.instance.clear());
  test(
      'Kakao Talk ID token exchanges with same nonce and stores ONARIA session',
      () async {
    final gateway = FakeKakaoGateway(talkToken: 'kakao-id-token');
    Map<String, dynamic>? body;
    final api = ProviderAuthApiClient(
        baseUrl: Uri.parse('https://api.onaria.ai.kr'),
        httpClient: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
              jsonEncode({'sessionToken': 'S' * 43, 'expiresInSeconds': 900}),
              201);
        }));
    await KakaoLoginService(
            api: api, gateway: gateway, enabled: true, random: Random(7))
        .login();
    expect(gateway.talkCalls, 1);
    expect(gateway.accountCalls, 0);
    expect(gateway.talkNonce, hasLength(64));
    expect(body?['provider'], 'kakao');
    expect(body?['credential'], 'kakao-id-token');
    expect(body?['nonce'], gateway.talkNonce);
    expect(MemberSessionStore.instance.token, 'S' * 43);
  });
  test('uses Kakao Account when Talk is not installed', () async {
    final gateway = FakeKakaoGateway(
        talkInstalled: false, accountToken: 'account-id-token');
    final api = ProviderAuthApiClient(
        baseUrl: Uri.parse('https://api.onaria.ai.kr'),
        httpClient: MockClient((_) async => http.Response(
            jsonEncode({'sessionToken': 'T' * 43, 'expiresInSeconds': 900}),
            201)));
    await KakaoLoginService(
            api: api, gateway: gateway, enabled: true, random: Random(9))
        .login();
    expect(gateway.talkCalls, 0);
    expect(gateway.accountCalls, 1);
    expect(gateway.accountNonce, hasLength(64));
  });
  test('fails closed before SDK/network when Kakao is not configured',
      () async {
    final gateway = FakeKakaoGateway(talkToken: 'x');
    final api = ProviderAuthApiClient(
        baseUrl: Uri.parse('https://api.onaria.ai.kr'),
        httpClient: MockClient((_) async => http.Response('{}', 500)));
    await expectLater(
        KakaoLoginService(api: api, gateway: gateway, enabled: false).login(),
        throwsA(isA<KakaoLoginException>()));
    expect(gateway.talkCalls, 0);
    expect(gateway.accountCalls, 0);
  });
}
