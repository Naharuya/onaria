import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/src/auth/naver_login_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('naver_login_flutter');
  final calls = <String>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'logOut') return {'status': 'loggedOut'};
      if (call.method == 'logIn') {
        return {
          'status': 'loggedIn',
          'accessToken': {'accessToken': 'fresh-fixture-token'},
        };
      }
      throw PlatformException(code: 'unexpected');
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  test('relogin clears SDK cache before obtaining the new credential',
      () async {
    expect(await NaverLoginService().authenticate(), 'fresh-fixture-token');
    expect(calls, ['logOut', 'logIn']);
    expect(calls, isNot(contains('logOutAndDeleteToken')));
  });

  test('SDK reset failure stops login and does not expose native error',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      throw PlatformException(
          code: 'fixture', message: 'private-fixture-value');
    });
    await expectLater(
      NaverLoginService().authenticate(),
      throwsA(isA<NaverLoginException>().having((error) => error.message,
          'safe message', isNot(contains('private-fixture-value')))),
    );
    expect(calls, ['logOut']);
  });
  test('native cleanup failure cannot be treated as successful logout',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return {
        'status': 'error',
        'errorMessage': 'errorCode:sdk_cleanup_failed'
      };
    });
    await expectLater(NaverLoginService().authenticate(),
        throwsA(isA<NaverLoginException>()));
    expect(calls, ['logOut']);
  });
  test('SDK error classification never exposes native payload or unknown codes',
      () {
    expect(
        safeNaverSdkErrorCode(
            'errorCode:invalid_client, errorDesc:private-fixture-value'),
        'invalid_client');
    expect(
        safeNaverSdkErrorCode('errorCode:401, errorDesc:private-fixture-value'),
        '401');
    expect(safeNaverSdkErrorCode('errorCode:private-fixture-value'), 'unknown');
    expect(safeNaverSdkErrorCode('payload 401 token private-fixture-value'),
        'unknown');
    expect(safeNaverSdkErrorCode(null, loggedOut: true), 'logged_out');
    expect(
        safeNaverSdkErrorCode(
            'Failed to parse user info: private-fixture-value'),
        'profile_response_invalid');
  });
  test(
      'native cancellation and successful callback without token stay distinct',
      () async {
    for (final code in ['user_cancel', 'success_token_missing']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'logOut') return {'status': 'loggedOut'};
        return {'status': 'error', 'errorMessage': 'errorCode:$code'};
      });
      await expectLater(
          NaverLoginService().authenticate(),
          throwsA(isA<NaverLoginException>()
              .having((e) => e.code, 'branch', code)));
      expect(safeNaverSdkErrorCode('errorCode:$code', loggedOut: true), code);
    }
  });

  test('SDK login failure reports safe code and never returns credential',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'logOut') return {'status': 'loggedOut'};
      return {
        'status': 'error',
        'errorMessage':
            'errorCode:invalid_client, errorDesc:private-fixture-value'
      };
    });
    await expectLater(
        NaverLoginService().authenticate(),
        throwsA(isA<NaverLoginException>()
            .having((e) => e.code, 'code', 'invalid_client')
            .having((e) => e.message, 'private payload',
                isNot(contains('private-fixture-value')))));
  });

  test(
      'timed-out native request blocks overlap and late success cannot become a new login',
      () async {
    final native = Completer<Map<String, Object?>>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'logOut') return {'status': 'loggedOut'};
      return native.future;
    });
    await expectLater(
        NaverLoginService(loginTimeout: const Duration(milliseconds: 10))
            .authenticate(),
        throwsA(isA<NaverLoginException>()
            .having((e) => e.code, 'timeout', 'timeout')));
    await expectLater(
        NaverLoginService().authenticate(),
        throwsA(isA<NaverLoginException>()
            .having((e) => e.code, 'busy', 'login_in_progress')));
    native.complete({
      'status': 'loggedIn',
      'accessToken': {'accessToken': 'late-fixture-token'}
    });
    await Future<void>.delayed(Duration.zero);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            channel,
            (call) async => call.method == 'logOut'
                ? {'status': 'loggedOut'}
                : {
                    'status': 'loggedIn',
                    'accessToken': {'accessToken': 'fresh-fixture-token'}
                  });
    expect(await NaverLoginService().authenticate(), 'fresh-fixture-token');
  });
}
