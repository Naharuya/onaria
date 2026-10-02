import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/src/api/provider_auth_api_client.dart';

void main() {
  final base = Uri.parse('https://api.onaria.ai.kr');
  test(
      'provider credential exchange is POST, no redirect, and parses opaque session',
      () async {
    late http.BaseRequest captured;
    final client = ProviderAuthApiClient(
        baseUrl: base,
        httpClient: MockClient.streaming((request, _) async {
          captured = request;
          return http.StreamedResponse(
              Stream.value(utf8.encode(jsonEncode(
                  {'sessionToken': 'A' * 43, 'expiresInSeconds': 900}))),
              201,
              headers: {'content-type': 'application/json'});
        }));
    final session = await client.exchange(
        provider: 'google', credential: 'provider-id-token');
    expect(captured.method, 'POST');
    expect(captured.url.path, '/v1/auth/provider/session');
    expect(captured.followRedirects, isFalse);
    expect(jsonDecode((captured as http.Request).body),
        {'provider': 'google', 'credential': 'provider-id-token'});
    expect(session.token, 'A' * 43);
    expect(session.expiresInSeconds, 900);
  });

  test('logout and account deletion send only ONARIA member session header',
      () async {
    final requests = <http.BaseRequest>[];
    final client = ProviderAuthApiClient(
        baseUrl: base,
        httpClient: MockClient.streaming((request, _) async {
          requests.add(request);
          return http.StreamedResponse(const Stream.empty(), 204);
        }));
    await client.logout('B' * 43);
    await client.deleteAccount('C' * 43);
    expect(requests.map((r) => r.url.path),
        ['/v1/auth/provider/session', '/v1/account']);
    expect(requests[0].headers['X-Onaria-Member-Session'], 'B' * 43);
    expect(requests[1].headers['X-Onaria-Member-Session'], 'C' * 43);
    expect(
        requests.every((r) => !r.headers.containsKey('X-Soul-Identity-Token')),
        isTrue);
  });

  test('invalid provider and malformed session response fail closed', () async {
    final client = ProviderAuthApiClient(
        baseUrl: base,
        httpClient: MockClient((_) async => http.Response('{}', 201)));
    expect(() => client.exchange(provider: 'phone', credential: 'x'),
        throwsA(isA<FormatException>()));
    await expectLater(
        client.exchange(provider: 'naver', credential: 'valid-token'),
        throwsA(isA<FormatException>()));
  });
}
