import 'dart:async';
import 'package:naver_login_flutter/naver_login_flutter.dart';

class NaverLoginService {
  // Local SDK logout only: never disconnect or revoke the provider account.
  Future<void> signOut() async {
    try {
      final result = await FlutterNaverLogin.logOut()
          .timeout(const Duration(seconds: 15));
      if (result.status != NaverLoginStatus.loggedOut) {
        throw const NaverLoginException('네이버 인증 상태를 정리하지 못했어요. 다시 시도해 주세요.');
      }
    } on NaverLoginException {
      rethrow;
    } catch (_) {
      throw const NaverLoginException('네이버 인증 상태를 정리하지 못했어요. 다시 시도해 주세요.');
    }
  }

  Future<String> authenticate() async {
    try {
      // ONARIA session revocation does not clear the native provider cache.
      // Start a fresh SDK authorization before forwarding its new token.
      await signOut();
      final result =
          await FlutterNaverLogin.logIn().timeout(const Duration(seconds: 90));
      if (result.status != NaverLoginStatus.loggedIn) {
        final detail = (result.errorMessage ?? '').trim();
        throw NaverLoginException(RegExp(r'\b401\b').hasMatch(detail)
            ? '네이버 SDK 인증 단계에서 401 오류가 발생했어요. 다시 시도해 주세요.'
            : '네이버 SDK 로그인을 완료하지 못했어요. 다시 시도해 주세요.');
      }
      final token = result.accessToken?.accessToken ?? '';
      if (token.isEmpty) {
        throw const NaverLoginException('네이버 인증 정보를 확인하지 못했습니다.');
      }
      return token;
    } on TimeoutException {
      throw const NaverLoginException(
          '네이버 인증 응답이 지연되고 있어요. 로그인 창을 닫고 다시 시도해 주세요.');
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
