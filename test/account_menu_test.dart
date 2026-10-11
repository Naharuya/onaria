import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:onaria/app/member_auth_controller.dart';
import 'package:onaria/app/member_session_store.dart';
import 'package:onaria/features/account_menu.dart';
import 'package:onaria/src/api/provider_auth_api_client.dart';

import 'member_auth_controller_test.dart' show AuthMemoryPersistence;

void main() {
  setUp(() => PackageInfo.setMockInitialValues(
        appName: 'ONARIA',
        packageName: 'com.onaria.app',
        version: '1.2.3',
        buildNumber: '987',
        buildSignature: '',
      ));
  testWidgets('live menu checks session then exposes logout without deletion',
      (tester) async {
    final store = MemberSessionStore.forTesting(AuthMemoryPersistence());
    store.set(token: 'A' * 43, expiresInSeconds: 3600);
    final account = Completer<http.Response>();
    final deletes = <String>[];
    final auth = MemberAuthController(
      sessions: store,
      signOutNaver: () async {},
      clientFactory: () => ProviderAuthApiClient(
          baseUrl: Uri.parse('https://api.onaria.ai.kr'),
          httpClient: MockClient((request) async {
            if (request.method == 'DELETE') {
              deletes.add(request.url.path);
              return http.Response('', 204);
            }
            return account.future;
          })),
    );
    addTearDown(auth.dispose);
    addTearDown(store.dispose);
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AccountMenuButton(controller: auth))));
    await tester.tap(find.byTooltip('메뉴'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('확인 중'), findsOneWidget);
    expect(find.text('로그인됨 · 네이버'), findsNothing);
    account.complete(http.Response(
        '{"providers":["naver","apple"],"currentProvider":"naver"}', 200));
    await tester.pumpAndSettle();
    expect(find.text('로그인됨 · 네이버'), findsOneWidget);
    expect(find.text('계정 관리'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('menu-app-info')), 250);
    await tester.pumpAndSettle();
    expect(find.text('앱 정보'), findsOneWidget);
    expect(find.text('버전 1.2.3 · 빌드 987'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('menu-logout')), -250);
    expect(find.text('회원탈퇴'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('menu-logout')));
    await tester.pumpAndSettle();
    expect(deletes, ['/v1/auth/provider/session']);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('menu-auth-status')), -250);
    await tester.pumpAndSettle();
    expect(find.text('로그인하지 않음'), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-login')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-logout')), findsNothing);
  });
}
