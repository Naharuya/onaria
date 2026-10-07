import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
// The SDK's platform interface lets these tests avoid native account UI.
// ignore: depend_on_referenced_packages
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:naver_login_flutter/naver_login_flutter.dart';
import 'package:naver_login_flutter/naver_login_flutter_platform_interface.dart';
import 'package:onaria/src/auth/google_login_service.dart';
import 'package:onaria/src/auth/naver_login_service.dart';

class GoogleStub extends GoogleSignInPlatform {
  int initializations = 0;
  bool pending = false;
  @override
  Future<void> init(InitParameters params) async {
    initializations++;
  }

  @override
  Stream<AuthenticationEvent>? get authenticationEvents => null;
  @override
  bool supportsAuthenticate() => true;
  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) {
    if (pending) return Completer<AuthenticationResults>().future;
    return Future.value(const AuthenticationResults(
      user:
          GoogleSignInUserData(email: 'synthetic@example.invalid', id: 'test'),
      authenticationTokens: AuthenticationTokenData(idToken: 'synthetic-token'),
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class NaverStub extends FlutterNaverLoginPlatform {
  @override
  Future<NaverLoginResult> logOut() async =>
      NaverLoginResult(status: NaverLoginStatus.loggedOut);
  @override
  Future<NaverLoginResult> logIn() => Completer<NaverLoginResult>().future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
      'Google shares initialization across attempts and ends a lost callback',
      (tester) async {
    final original = GoogleSignInPlatform.instance;
    final stub = GoogleStub();
    GoogleSignInPlatform.instance = stub;
    addTearDown(() => GoogleSignInPlatform.instance = original);
    expect(await GoogleLoginService().authenticate(), 'synthetic-token');
    expect(await GoogleLoginService().authenticate(), 'synthetic-token');
    expect(stub.initializations, 1);
    stub.pending = true;
    final check = expectLater(
        GoogleLoginService().authenticate(),
        throwsA(isA<GoogleLoginException>()
            .having((e) => e.message, 'message', contains('지연'))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 91));
    await check;
  });

  testWidgets('Naver ends a lost native callback with a recoverable message',
      (tester) async {
    final original = FlutterNaverLoginPlatform.instance;
    FlutterNaverLoginPlatform.instance = NaverStub();
    addTearDown(() => FlutterNaverLoginPlatform.instance = original);
    final check = expectLater(
        NaverLoginService().authenticate(),
        throwsA(isA<NaverLoginException>()
            .having((e) => e.message, 'message', contains('지연'))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 91));
    await check;
  });
}
