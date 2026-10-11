import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/features/signup_page.dart';
import 'package:onaria/src/api/member_api_client.dart';
import 'package:onaria/app/member_session_store.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _SessionMemory implements MemberSessionPersistence {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

void main() {
  late MemberSessionStore sessions;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    sessions = MemberSessionStore.forTesting(_SessionMemory());
  });
  tearDown(() {
    sessions.clear();
    sessions.dispose();
  });
  Future<void> open(
      WidgetTester tester, Future<http.Response> Function(http.Request) handler,
      {double textScale = 1}) async {
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => SignUpPage(
                                  sessionStore: sessions,
                                  credentialLoader: (provider) async =>
                                      'proof-$provider',
                                  memberClientFactory: () => MemberApiClient(
                                      baseUrl:
                                          Uri.parse('https://api.onaria.ai.kr'),
                                      httpClient: MockClient(handler)),
                                ))),
                    child: const Text('시작'))))));
    await tester.tap(find.text('시작'));
    await tester.pumpAndSettle();
  }

  http.Response unknown() => http.Response(
      jsonEncode({'code': 'PROVIDER_IDENTITY_NOT_FOUND', 'message': 'unknown'}),
      404);
  Future<void> tap(WidgetTester tester, String label) async {
    if (find.text(label).evaluate().isEmpty) {
      await tester.scrollUntilVisible(find.text(label), 180);
    }
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'unknown identity offers explicit choice then consent without profile inputs',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    sessions.set(token: 'C' * 43, expiresInSeconds: 3600);
    await open(tester, (request) async {
      expect(request.url.path, '/v1/auth/provider/session');
      return unknown();
    });
    await tap(tester, '네이버로 계속하기');
    await tester.scrollUntilVisible(find.text('기존 ONARIA 계정에 연결'), 180);
    expect(find.text('기존 ONARIA 계정에 연결'), findsOneWidget);
    expect(find.text('이름 (선택)'), findsNothing);
    await tap(tester, '새 계정 만들기');
    await tester.scrollUntilVisible(find.text('시작하기 전 확인'), 180,
        scrollable: find.byType(Scrollable).first);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('만 18세 이상입니다. (필수)'), findsOneWidget);
  });
  testWidgets(
      'failed existing proof preserves pending credential; successful retry stores linked session',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var attempts = 0;
    await open(tester, (request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (request.url.path.endsWith('/session')) {
        if (body['provider'] == 'naver') return unknown();
        if (++attempts == 1) return unknown();
        return http.Response(
            jsonEncode({'sessionToken': 'A' * 43, 'expiresInSeconds': 3600}),
            201);
      }
      expect(request.url.path, '/v1/account/providers');
      expect(body, {
        'provider': 'naver',
        'credential': 'proof-naver',
        'reauthProvider': 'google',
        'reauthCredential': 'proof-google'
      });
      expect(request.headers['X-Onaria-Member-Session'], 'A' * 43);
      return http.Response(
          jsonEncode({
            'member': {'id': 7},
            'sessionToken': 'B' * 43,
            'expiresInSeconds': 3600
          }),
          200);
    });
    await tap(tester, '네이버로 계속하기');
    await tap(tester, '기존 ONARIA 계정에 연결');
    expect(find.text('기존 ONARIA 계정으로 본인 확인'), findsOneWidget);
    await tap(tester, 'Google로 계속하기');
    expect(find.text('기존 ONARIA 계정으로 본인 확인'), findsOneWidget);
    expect(sessions.token, isNull);
    await tap(tester, 'Google로 계속하기');
    expect(sessions.token, 'B' * 43);
    expect(find.text('시작'), findsOneWidget);
  });
  testWidgets(
      'unrelated 404 never enables signup and small screen keeps provider order',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(
        tester,
        (_) async => http.Response(
            '{"code":"ROUTE_NOT_FOUND","message":"failed"}', 404));
    await tap(tester, '네이버로 계속하기');
    expect(find.text('새 계정 만들기'), findsNothing);
    expect(tester.takeException(), isNull);
    final apple =
        tester.getTopLeft(find.byKey(const ValueKey('apple-signup'))).dy;
    final google =
        tester.getTopLeft(find.byKey(const ValueKey('google-signup'))).dy;
    expect(apple, lessThan(google));
  });
  testWidgets('unknown identity choice fits small screen with large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await open(tester, (_) async => unknown(), textScale: 2);
    await tap(tester, '네이버로 계속하기');
    expect(find.byKey(const ValueKey('link-existing-account')).hitTestable(),
        findsOneWidget);
    expect(find.byKey(const ValueKey('apple-signup')), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    await tap(tester, '기존 ONARIA 계정에 연결');
    expect(find.text('기존 ONARIA 계정으로 본인 확인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
