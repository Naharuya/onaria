import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/src/api/auth_diagnostics.dart';
import 'package:onaria/src/api/member_api_client.dart';
import 'package:onaria/src/api/provider_auth_api_client.dart';

void main() {
  test('failure diagnostics allow fixed reasons only', () {
    final previous = debugPrint;
    final events = <String>[];
    debugPrint = (message, {wrapWidth}) {
      if (message != null) events.add(message);
    };
    try {
      AuthDiagnostics.failure('GET', '/v1/account', 'private-error');
      AuthDiagnostics.failure('GET', '/v1/account?private', 'timeout');
      expect(events, isEmpty);
      AuthDiagnostics.failure('GET', '/v1/account', 'timeout');
      expect(
          events,
          AuthDiagnostics.enabled
              ? ['ONARIA_AUTH_STATUS operation=account failure=timeout']
              : isEmpty);
    } finally {
      debugPrint = previous;
    }
  });
  test('temporary diagnostic export is bounded and rejects secret content',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('onaria-diag-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/status.log');
    await AuthDiagnostics.persistTo(file, 'private-proof');
    expect(await file.exists(), isFalse);
    await file.writeAsString('private-response\n');
    for (var i = 0; i < 66; i++) {
      await AuthDiagnostics.persistTo(
          file, 'ONARIA_AUTH_STATUS operation=account status=200');
    }
    final lines = await file.readAsLines();
    expect(lines, hasLength(64));
    expect(
        lines.every((line) =>
            line == 'ONARIA_AUTH_STATUS operation=account status=200'),
        isTrue);
    await AuthDiagnostics.persistTo(file,
        'ONARIA_AUTH_STATUS operation=account status=200 credential=private');
    expect(await file.readAsLines(), lines);
  });
  late List<String> events;
  late DebugPrintCallback previous;

  setUp(() {
    events = [];
    previous = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) events.add(message);
    };
  });
  tearDown(() => debugPrint = previous);

  test('login and logout record only fixed operation and HTTP status',
      () async {
    final member = MemberApiClient(
      baseUrl: Uri.parse('https://api.onaria.ai.kr'),
      httpClient: MockClient((_) async => http.Response(
          jsonEncode({
            'sessionToken': 'A' * 43,
            'expiresInSeconds': 900,
          }),
          201)),
    );
    final provider = ProviderAuthApiClient(
      baseUrl: Uri.parse('https://api.onaria.ai.kr'),
      httpClient: MockClient((_) async => http.Response('', 204)),
    );
    addTearDown(member.close);
    addTearDown(provider.close);
    await member.providerSession(
        provider: 'naver', credential: 'private-proof');
    await provider.logout('private-session');
    expect(
        events,
        AuthDiagnostics.enabled
            ? [
                'ONARIA_AUTH_STATUS operation=login status=201',
                'ONARIA_AUTH_STATUS operation=logout status=204',
              ]
            : isEmpty);
  });

  test('rejected login records 401 without response error or credential',
      () async {
    final client = MemberApiClient(
      baseUrl: Uri.parse('https://api.onaria.ai.kr'),
      httpClient: MockClient((_) async =>
          http.Response(jsonEncode({'message': 'private-response'}), 401)),
    );
    addTearDown(client.close);
    await expectLater(
      client.providerSession(provider: 'naver', credential: 'private-proof'),
      throwsA(isA<MemberApiException>()),
    );
    expect(
        events,
        AuthDiagnostics.enabled
            ? [
                'ONARIA_AUTH_STATUS operation=login status=401',
              ]
            : isEmpty);
  });

  test('unknown paths, query strings and invalid statuses cannot be logged',
      () {
    AuthDiagnostics.record('GET', '/v1/account?credential=private', 200);
    AuthDiagnostics.record('POST', '/unknown/private', 200);
    AuthDiagnostics.record('POST', '/v1/auth/provider/session', 999);
    expect(events, isEmpty);
  });
}
