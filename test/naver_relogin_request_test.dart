import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/src/api/member_api_client.dart';
import 'package:onaria/src/api/provider_auth_api_client.dart';

void main() {
  test('existing member relogin sends fresh Naver credential without old ONARIA session', () async {
    final requests = <http.Request>[];
    var issued = 0;
    final transport = MockClient((request) async {
      requests.add(request);
      if (request.method == 'DELETE') return http.Response('', 204);
      issued++;
      return http.Response(jsonEncode({
        'sessionToken': (issued == 1 ? 'A' : 'B') * 43,
        'expiresInSeconds': 3600,
      }), 201);
    });
    final base = Uri.parse('https://api.onaria.ai.kr');
    final members = MemberApiClient(baseUrl: base, httpClient: transport);
    final auth = ProviderAuthApiClient(baseUrl: base, httpClient: transport);
    final first = await members.providerSession(provider: 'naver', credential: 'first-fixture');
    await auth.logout(first.token);
    final second = await members.providerSession(provider: 'naver', credential: 'fresh-fixture==');
    expect(second.token, isNot(first.token));
    expect(requests.map((request) => request.method), ['POST', 'DELETE', 'POST']);
    expect(requests.every((request) => request.url.path == '/v1/auth/provider/session'), isTrue);
    expect(requests[1].headers['X-Onaria-Member-Session'], first.token);
    expect(requests[2].headers.containsKey('X-Onaria-Member-Session'), isFalse);
    expect(jsonDecode(requests[2].body), {'provider': 'naver', 'credential': 'fresh-fixture=='});
  });
}
