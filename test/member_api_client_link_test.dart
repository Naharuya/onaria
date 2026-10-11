import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/src/api/member_api_client.dart';

void main() {
  final base = Uri.parse('https://api.onaria.ai.kr');

  test('provider linking uses dedicated authenticated account endpoint',
      () async {
    late http.Request captured;
    final client = MemberApiClient(
      baseUrl: base,
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(
            jsonEncode({
              'member': {'id': 3},
              'sessionToken': 'A' * 43,
              'expiresInSeconds': 3600,
              'linked': true,
            }),
            200,
            headers: {'content-type': 'application/json'});
      }),
    );
    final linked = await client.linkProvider(
      provider: 'naver',
      credential: 'provider-proof',
      sessionToken: 'B' * 43,
    );
    expect(captured.url.path, '/v1/account/providers');
    expect(captured.headers['X-Onaria-Member-Session'], 'B' * 43);
    expect(jsonDecode(captured.body),
        {'provider': 'naver', 'credential': 'provider-proof'});
    expect(linked.memberId, 3);
    client.close();
  });

  test('structured provider conflict code is exposed to the app', () async {
    final client = MemberApiClient(
      baseUrl: base,
      httpClient: MockClient((_) async => http.Response(
            jsonEncode({
              'code': 'IDENTITY_ALREADY_REGISTERED',
              'message': '이미 가입된 소셜 계정입니다.'
            }),
            409,
            headers: {'content-type': 'application/json'},
          )),
    );
    try {
      await client.providerSignUp(
        provider: 'google',
        credential: 'proof',
        name: '',
        phone: '',
        churchName: '',
        adultConfirmed: true,
      );
      fail('expected MemberApiException');
    } on MemberApiException catch (error) {
      expect(error.statusCode, 409);
      expect(error.code, 'IDENTITY_ALREADY_REGISTERED');
    }
    client.close();
  });
}
