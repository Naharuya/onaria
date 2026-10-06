import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/features/signup_page.dart';

void main() {
  testWidgets(
      'signup details stay hidden until a new social identity is verified',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpPage()));
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('회원 정보'), findsNothing);
    expect(find.text('기존 회원은 바로 로그인되고, 처음 이용하는 계정만 아래 회원 정보로 가입을 완료합니다.'),
        findsOneWidget);
  });
}
