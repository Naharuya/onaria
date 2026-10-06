import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/kakao_auth_config.dart';

void main() {
  test('Kakao auth is fail-closed when no native app key is injected', () {
    expect(KakaoAuthConfig.nativeAppKey, isEmpty);
    expect(KakaoAuthConfig.enabled, isFalse);
    expect(KakaoAuthConfig.initialize, returnsNormally);
  });
}
