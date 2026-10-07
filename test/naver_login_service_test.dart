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
  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  test('relogin clears SDK cache before obtaining the new credential', () async {
    expect(await NaverLoginService().authenticate(), 'fresh-fixture-token');
    expect(calls, ['logOut', 'logIn']);
    expect(calls, isNot(contains('logOutAndDeleteToken')));
  });

  test('SDK reset failure stops login and does not expose native error', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      throw PlatformException(code: 'fixture', message: 'private-fixture-value');
    });
    await expectLater(
      NaverLoginService().authenticate(),
      throwsA(isA<NaverLoginException>().having(
          (error) => error.message, 'safe message', isNot(contains('private-fixture-value')))),
    );
    expect(calls, ['logOut']);
  });
}
