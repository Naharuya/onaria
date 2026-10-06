import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/member_session_store.dart';
import 'package:onaria/features/privacy_page.dart';

void main() {
  tearDown(() => MemberSessionStore.instance.clear());

  testWidgets('account actions stay available when account lookup fails',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Flutter widget tests replace HttpClient with a client returning HTTP 400.
    // No real authentication provider or production account request is made.
    MemberSessionStore.instance.set(
      token: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ',
      expiresInSeconds: 3600,
    );
    await tester.pumpWidget(const MaterialApp(home: PrivacyPage()));
    await tester.pumpAndSettle();
    final logout = find.text('로그아웃');
    final deleteRecords = find.text('마음카드·실천 기록 전체 삭제');
    expect(logout, findsOneWidget);
    expect(find.text('로그인 상태입니다. 연결된 계정 정보를 불러오지 못해도 로그아웃할 수 있어요.'),
        findsOneWidget);
    expect(tester.getTopLeft(logout).dy,
        lessThan(tester.getTopLeft(deleteRecords).dy));
    expect(tester.takeException(), isNull);
  });
}
