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
    expect(find.text('가입할 때 사용한 계정을 선택해 주세요. 처음이라면 인증 후 가입을 이어갑니다.'),
        findsOneWidget);
  });
}
