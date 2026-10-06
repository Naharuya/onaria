import 'package:naver_login_flutter/naver_login_flutter.dart';

class NaverLoginService {
  Future<String> authenticate() async {
    try {
      final result = await FlutterNaverLogin.logIn();
      if (result.status != NaverLoginStatus.loggedIn) {
        final detail = (result.errorMessage ?? '').trim();
        throw NaverLoginException(
            detail.isEmpty ? '네이버 로그인을 완료하지 못했어요.' : '네이버 로그인 오류: $detail');
      }
      final token = result.accessToken?.accessToken ?? '';
      if (token.isEmpty) {
        throw const NaverLoginException('네이버 인증 정보를 확인하지 못했습니다.');
      }
      return token;
    } on NaverLoginException {
      rethrow;
    } catch (error) {
      throw NaverLoginException('네이버 로그인 오류: ${error.runtimeType}');
    }
  }
}

class NaverLoginException implements Exception {
  const NaverLoginException(this.message);
  final String message;
  @override
  String toString() => message;
}
