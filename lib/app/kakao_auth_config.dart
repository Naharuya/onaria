import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoAuthConfig {
  KakaoAuthConfig._();

  static const _channel = MethodChannel('onaria/config');
  static const _compileTimeValue =
      String.fromEnvironment('ONARIA_KAKAO_NATIVE_APP_KEY');
  static String _nativeAppKey = _compileTimeValue.trim();

  static String get nativeAppKey => _nativeAppKey;
  static bool get enabled => _nativeAppKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!kIsWeb && _nativeAppKey.isEmpty) {
      try {
        final value = await _channel.invokeMethod<String>('providerConfig');
        if (value != null && value.trim().isNotEmpty) {
          _nativeAppKey = value.trim();
        }
      } on PlatformException {
        // A missing native config keeps Kakao disabled; other providers remain available.
      } on MissingPluginException {
        // Unit tests and unsupported platforms may not register the native channel.
      }
    }
    if (enabled) KakaoSdk.init(nativeAppKey: _nativeAppKey);
  }

  @visibleForTesting
  static void resetForTesting([String value = '']) {
    _nativeAppKey = value.trim();
  }
}
