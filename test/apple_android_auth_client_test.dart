import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/src/auth/apple_android_auth_client.dart';

void main() {
  final base = Uri.parse('https://api.onaria.ai.kr');
  final valid = {
    'state': 'a' * 43, 'nonce': 'b' * 43, 'clientId': 'com.onaria.web',
    'redirectUri': 'https://api.onaria.ai.kr/v1/auth/apple/android/callback',
  };
  test('challenge is obtained from fixed API and returned proof is state-bound', () async {
    final client = AppleAndroidAuthClient(baseUrl: base,
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://api.onaria.ai.kr/v1/auth/apple/android/challenge');
        expect(request.followRedirects, isFalse);
        return http.Response(jsonEncode(valid), 200);
      }));
    final challenge = await client.challenge();
    final proof = 'apple_android.${'c' * 43}';
    expect(challenge.checkedProof(returnedState: 'a' * 43, token: proof), proof);
    expect(() => challenge.checkedProof(returnedState: 'x' * 43, token: proof), throwsFormatException);
    expect(() => challenge.checkedProof(returnedState: 'a' * 43, token: 'jwt'), throwsFormatException);
    client.close();
  });
  test('server errors, malformed challenge and foreign redirect fail closed', () async {
    for (final response in [http.Response('{}', 503), http.Response('{}', 200),
      http.Response(jsonEncode({...valid, 'redirectUri': 'https://evil.example/callback'}), 200)]) {
      final client = AppleAndroidAuthClient(baseUrl: base, httpClient: MockClient((_) async => response));
      await expectLater(client.challenge(), throwsFormatException); client.close();
    }
  });
}
