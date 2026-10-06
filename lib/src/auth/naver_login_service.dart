import 'package:naver_login_flutter/naver_login_flutter.dart';

class NaverLoginService {
  Future<String> authenticate() async {
    try {
      final result = await FlutterNaverLogin.logIn();
      if (result.status != NaverLoginStatus.loggedIn) {
        throw const NaverLoginException('네이버 로그인을 완료하지 못했어요.');
      }
      final token = result.accessToken?.accessToken ?? '';
      if (token.isEmpty) {
        throw const NaverLoginException('네이버 인증 정보를 확인하지 못했습니다.');
      }
      return token;
    } on NaverLoginException {
      rethrow;
    } catch (_) {
      throw const NaverLoginException('네이버 로그인을 완료하지 못했어요.');
    }
  }
}

class NaverLoginException implements Exception {
  const NaverLoginException(this.message);
  final String message;
  @override
  String toString() => message;
}
