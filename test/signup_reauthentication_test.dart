import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/features/signup_page.dart';
import 'package:onaria/src/api/member_api_client.dart';

void main() {
  for (final status in [401, 409]) {
    testWidgets(
        'signup $status preserves fields and requires fresh auth only for 401',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel =
          MethodChannel('com.aboutyou.dart_packages.sign_in_with_apple');
      var authentications = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
          (call) async {
        authentications++;
        return {
          'type': 'appleid',
          'authorizationCode': 'synthetic-code',
          'identityToken': 'synthetic-$authentications'
        };
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));
      final signupCredentials = <String>[];
      await tester.pumpWidget(MaterialApp(
          home: SignUpPage(
              memberClientFactory: (base) => MemberApiClient(
                  baseUrl: base,
                  httpClient: MockClient((request) async {
                    if (request.url.path.endsWith('/session'))
                      return http.Response('{"message":"new member"}', 404);
                    signupCredentials
                        .add(jsonDecode(request.body)['credential'] as String);
                    return http.Response(
                        jsonEncode({
                          'message': status == 401
                              ? '회원 인증이 필요합니다.'
                              : '이미 가입된 휴대폰 번호입니다.'
                        }),
                        status,
                        headers: {
                          'content-type': 'application/json; charset=utf-8'
                        });
                  })))));
      Future<void> tapText(String text) async {
        final f = find.text(text);
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await tapText('Apple로 계속하기');
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(3));
      await tester.enterText(fields.at(0), '테스트 이름');
      await tester.enterText(fields.at(1), '01012345678');
      await tester.enterText(fields.at(2), '테스트 교회');
      for (var i = 0; i < 3; i++) {
        final checkbox = find.byType(CheckboxListTile).at(i);
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
      }
      await tapText('Apple로 가입 완료');
      expect(signupCredentials, ['synthetic-1']);
      for (final value in ['테스트 이름', '01012345678', '테스트 교회']) {
        expect(find.text(value), findsOneWidget);
      }
      expect(
          tester
              .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
              .every((c) => c.value == true),
          isTrue);
      if (status == 401) {
        await tapText('Apple 다시 인증하기');
        expect(authentications, 2);
        await tapText('Apple로 가입 완료');
        expect(signupCredentials, ['synthetic-1', 'synthetic-2']);
      } else {
        expect(find.text('Apple 다시 인증하기'), findsNothing);
        expect(find.text('이미 가입된 휴대폰 번호입니다.'), findsOneWidget);
        expect(authentications, 1);
      }
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
