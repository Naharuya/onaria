import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/google_auth_config.dart';

class GoogleLoginService {
  GoogleLoginService({GoogleSignIn? signIn})
      : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  static Future<void>? _initialization;
  static Future<GoogleSignInAccount>? _pendingAuthentication;

  Future<String> authenticate() async {
    if (!GoogleAuthConfig.enabled) {
      throw const GoogleLoginException('Google 로그인이 아직 설정되지 않았습니다.');
    }
    try {
      final initialization = _initialization ??= _signIn.initialize(
        clientId: GoogleAuthConfig.clientId,
        serverClientId: GoogleAuthConfig.serverClientId,
      );
      try {
        await initialization.timeout(const Duration(seconds: 15));
      } catch (_) {
        if (identical(_initialization, initialization)) _initialization = null;
        rethrow;
      }
      if (!_signIn.supportsAuthenticate()) {
        throw const GoogleLoginException('이 기기에서는 Google 로그인을 사용할 수 없습니다.');
      }
      if (_pendingAuthentication != null) {
        throw const GoogleLoginException(
            '이전 Google 인증이 진행 중이에요. 로그인 창을 닫고 잠시 기다려 주세요.');
      }
      // A caller timeout does not cancel the native SDK. Hold the shared slot
      // until its real callback settles, including after this caller times out.
      final attempt = _signIn.authenticate();
      _pendingAuthentication = attempt;
      void release() {
        if (identical(_pendingAuthentication, attempt)) {
          _pendingAuthentication = null;
        }
      }

      unawaited(attempt.then<void>((_) => release(),
          onError: (Object _, StackTrace __) => release()));
      final account = await attempt.timeout(const Duration(seconds: 90));
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleLoginException('Google 인증 정보를 확인하지 못했습니다.');
      }
      return idToken;
    } on TimeoutException {
      throw const GoogleLoginException(
          'Google 인증 응답이 지연되고 있어요. 로그인 창을 닫고 다시 시도해 주세요.');
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleLoginException('Google 로그인이 취소되었습니다.');
      }
      throw const GoogleLoginException('Google 인증을 완료하지 못했어요. 다시 시도해 주세요.');
    } on GoogleLoginException {
      rethrow;
    } catch (_) {
      throw const GoogleLoginException('Google 로그인을 완료하지 못했습니다.');
    }
  }
}

class GoogleLoginException implements Exception {
  const GoogleLoginException(this.message);
  final String message;
  @override
  String toString() => message;
}
