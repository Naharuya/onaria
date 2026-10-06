import 'package:google_sign_in/google_sign_in.dart';

import '../../app/google_auth_config.dart';

class GoogleLoginService {
  GoogleLoginService({GoogleSignIn? signIn})
      : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  bool _initialized = false;

  Future<String> authenticate() async {
    if (!GoogleAuthConfig.enabled) {
      throw const GoogleLoginException('Google 로그인이 아직 설정되지 않았습니다.');
    }
    try {
      if (!_initialized) {
        await _signIn.initialize(
          clientId: GoogleAuthConfig.clientId,
          serverClientId: GoogleAuthConfig.serverClientId,
        );
        _initialized = true;
      }
      if (!_signIn.supportsAuthenticate()) {
        throw const GoogleLoginException('이 기기에서는 Google 로그인을 사용할 수 없습니다.');
      }
      final account = await _signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleLoginException('Google 인증 정보를 확인하지 못했습니다.');
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleLoginException('Google 로그인이 취소되었습니다.');
      }
      throw GoogleLoginException('Google 인증 오류: ${error.code.name}');
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
