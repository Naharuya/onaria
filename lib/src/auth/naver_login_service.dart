import 'dart:async';
import 'package:naver_login_flutter/naver_login_flutter.dart';
import 'package:flutter/foundation.dart';
import '../api/auth_diagnostics.dart';

class NaverLoginService {
  NaverLoginService({this.loginTimeout = const Duration(seconds: 90)});
  final Duration loginTimeout;
  static Future<String>? _pendingLogin;

  Future<String> authenticate() async {
    if (_pendingLogin != null) {
      throw const NaverLoginException(
          '이전 네이버 인증이 진행 중이에요. 로그인 창을 닫고 잠시 기다려 주세요.',
          code: 'login_in_progress');
    }
    final attempt = _authenticate();
    _pendingLogin = attempt;
    // Timeout only stops this caller. Do not start a second native request
    // until the old callback has actually settled.
    unawaited(attempt.then<void>((_) {
      _pendingLogin = null;
    }, onError: (Object _, StackTrace __) {
      _pendingLogin = null;
    }));
    try {
      return await attempt.timeout(loginTimeout);
    } on TimeoutException {
      throw const NaverLoginException(
          '네이버 인증 응답이 지연되고 있어요. 로그인 창을 닫고 다시 시도해 주세요.',
          code: 'timeout');
    }
  }

  // Local SDK logout only: never disconnect or revoke the provider account.
  Future<void> signOut() async {
    try {
      await _signOutRaw().timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const NaverLoginException('네이버 인증 상태를 정리하지 못했어요. 다시 시도해 주세요.',
          code: 'sdk_cleanup_failed');
    }
  }

  Future<void> _signOutRaw() async {
    try {
      final result = await FlutterNaverLogin.logOut();
      if (result.status != NaverLoginStatus.loggedOut) {
        throw const NaverLoginException('네이버 인증 상태를 정리하지 못했어요. 다시 시도해 주세요.');
      }
    } on NaverLoginException {
      rethrow;
    } catch (_) {
      throw const NaverLoginException('네이버 인증 상태를 정리하지 못했어요. 다시 시도해 주세요.');
    }
  }

  Future<String> _authenticate() async {
    try {
      // ONARIA session revocation does not clear the native provider cache.
      // Start a fresh SDK authorization before forwarding its new token.
      await _signOutRaw();
      final result = await FlutterNaverLogin.logIn();
      if (result.status != NaverLoginStatus.loggedIn) {
        final code = safeNaverSdkErrorCode(result.errorMessage,
            loggedOut: result.status == NaverLoginStatus.loggedOut);
        if (AuthDiagnostics.enabled) {
          debugPrint('ONARIA_NAVER_SDK stage=login code=$code');
        }
        final message = switch (code) {
          'user_cancel' => '네이버 인증이 취소되었어요. 다시 시도해 주세요.',
          'success_token_missing' => '네이버 인증 정보를 확인하지 못했어요. 다시 시도해 주세요.',
          'logged_out' => '네이버 로그인이 완료되지 않았어요. 다시 시도해 주세요.',
          'invalid_client' || 'unauthorized_client' => '네이버 앱 등록정보를 확인해야 해요.',
          'access_denied' => '네이버 인증 동의가 완료되지 않았어요.',
          '401' => '네이버 인증을 확인하지 못했어요. 다시 시도해 주세요.',
          _ => '네이버 로그인을 완료하지 못했어요. 다시 시도해 주세요.',
        };
        throw NaverLoginException(message, code: code);
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
      throw const NaverLoginException('네이버 로그인을 완료하지 못했어요. 다시 시도해 주세요.',
          code: 'unknown');
    }
  }
}

class NaverLoginException implements Exception {
  const NaverLoginException(this.message, {this.code});
  final String? code;
  final String message;
  @override
  String toString() => message;
}

// Never expose the native message: it may include provider payloads or secrets.
String safeNaverSdkErrorCode(String? message, {bool loggedOut = false}) {
  if ((message ?? '').startsWith('Failed to parse user info:'))
    return 'profile_response_invalid';
  if ((message ?? '').startsWith('Failed to get user info:'))
    return 'profile_request_failed';
  if ((message ?? '').startsWith('SDK not initialized.'))
    return 'sdk_not_initialized';
  final match = RegExp(r'(?:errorCode|error_code)\s*[:=]\s*([A-Za-z0-9_-]+)',
          caseSensitive: false)
      .firstMatch(message ?? '');
  final code = match?.group(1)?.toLowerCase();
  const allowed = {
    'invalid_client',
    'unauthorized_client',
    'invalid_request',
    'invalid_grant',
    'invalid_token',
    'access_denied',
    'user_cancel',
    'success_token_missing',
    '400',
    '401',
    '403',
    '404',
    '408',
    '429',
    '500',
    '502',
    '503',
    '504'
  };
  return allowed.contains(code)
      ? code!
      : (loggedOut ? 'logged_out' : 'unknown');
}
