import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/features/signup_page.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform displays four providers in requested order', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));
      final keys = [
        'apple-signup',
        'google-signup',
        'naver-signup',
        'kakao-signup',
      ];
      double previousY = -1;
      for (final key in keys) {
        final finder = find.byKey(ValueKey(key));
        expect(finder, findsOneWidget);
        final rect = tester.getRect(finder);
        expect(rect.top, greaterThan(previousY));
        expect(rect.height, greaterThanOrEqualTo(52));
        previousY = rect.bottom;
      }
      expect(find.text('회원 정보'), findsNothing);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('unavailable Android Apple server preserves signup state',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(const MaterialApp(home: SignUpPage()));
    await tester.ensureVisible(find.byKey(const ValueKey('apple-signup')));
    await tester.tap(find.byKey(const ValueKey('apple-signup')));
    await tester.pump();
    expect(find.text('안드로이드 Apple 로그인 서버 연결을 준비 중이에요. 다른 방법으로 로그인해 주세요.'),
        findsOneWidget);
    expect(find.text('회원 정보'), findsNothing);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('small screen and enlarged text can scroll to last provider', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const SignUpPage(),
      ),
    );
    final last = find.byKey(const ValueKey('kakao-signup'));
    await tester.scrollUntilVisible(last, 200,
        scrollable: find.byType(Scrollable));
    await tester.pumpAndSettle();
    expect(last.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
