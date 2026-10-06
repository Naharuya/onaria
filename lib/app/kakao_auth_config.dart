import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoAuthConfig {
  static const nativeAppKey =
      String.fromEnvironment('ONARIA_KAKAO_NATIVE_APP_KEY');
  static bool get enabled => nativeAppKey.trim().isNotEmpty;

  static void initialize() {
    if (!enabled) return;
    KakaoSdk.init(nativeAppKey: nativeAppKey);
  }
}
