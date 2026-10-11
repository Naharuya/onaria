import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../app/api_config.dart';
import 'auth_diagnostics.dart';

class MemberApiClient {
  MemberApiClient(
      {required this.baseUrl,
      http.Client? httpClient,
      this.timeout = const Duration(seconds: 15)})
      : _httpClient = httpClient ?? http.Client();
  final Uri baseUrl;
  final http.Client _httpClient;
  final Duration timeout;

  Future<MemberRegistration> signUp(
      {required String name,
      required String phone,
      required String churchName,
      String loginProvider = 'phone',
      bool adultConfirmed = false}) async {
    ApiConfig.requireSecureEndpoint(baseUrl);
    final request = http.Request('POST', baseUrl.resolve('/v1/auth/signup'))
      ..followRedirects = false
      ..headers.addAll(const {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      })
      ..body = jsonEncode({
        'name': name,
        'phone': phone,
        'churchName': churchName,
        'loginProvider': loginProvider,
        'termsAccepted': true,
        'privacyAccepted': true,
        'adultConfirmed': adultConfirmed
      });
    final response = await _httpClient
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MemberApiException(_readError(response.body));
    }
    try {
      final decoded = jsonDecode(response.body);
      final member = decoded is Map<String, dynamic> ? decoded['member'] : null;
      if (member is! Map || member['id'] is! int || member['id'] < 1) {
        throw const FormatException('Invalid member response');
      }
      return MemberRegistration(memberId: member['id'] as int);
    } catch (error) {
      if (error is FormatException) rethrow;
      throw const FormatException('Invalid member response');
    }
  }

  Future<MemberSession> providerSession({
    required String provider,
    required String credential,
  }) async {
    ApiConfig.requireSecureEndpoint(baseUrl);
    final response = await _postJson('/v1/auth/provider/session', {
      'provider': provider,
      'credential': credential,
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MemberApiException(
        _readError(response.body),
        statusCode: response.statusCode,
        code: _readCode(response.body),
      );
    }
    return _readSession(response.body);
  }

  Future<AuthenticatedMemberRegistration> linkProvider({
    required String provider,
    required String credential,
    required String sessionToken,
    String? reauthProvider,
    String? reauthCredential,
  }) async {
    ApiConfig.requireSecureEndpoint(baseUrl);
    final response = await _postJson(
      '/v1/account/providers',
      {
        'provider': provider,
        'credential': credential,
        if (reauthProvider != null) 'reauthProvider': reauthProvider,
        if (reauthCredential != null) 'reauthCredential': reauthCredential,
      },
      sessionToken: sessionToken,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MemberApiException(
        _readError(response.body),
        statusCode: response.statusCode,
        code: _readCode(response.body),
      );
    }
    return _readAuthenticatedRegistration(response.body);
  }

  Future<AuthenticatedMemberRegistration> providerSignUp({
    required String provider,
    required String credential,
    required String name,
    required String phone,
    required String churchName,
    required bool adultConfirmed,
  }) async {
    ApiConfig.requireSecureEndpoint(baseUrl);
    final response = await _postJson(
      '/v1/auth/provider/signup',
      {
        'provider': provider,
        'credential': credential,
        'name': name,
        'phone': phone,
        'churchName': churchName,
        'termsAccepted': true,
        'privacyAccepted': true,
        'termsVersion': '2026-10-07-adult',
        'privacyVersion': '2026-10-07',
        'adultConfirmed': adultConfirmed,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MemberApiException(
        _readError(response.body),
        statusCode: response.statusCode,
        code: _readCode(response.body),
      );
    }
    return _readAuthenticatedRegistration(response.body);
  }

  Future<http.Response> _postJson(
    String path,
    Map<String, Object?> body, {
    String? sessionToken,
  }) {
    final request = http.Request('POST', baseUrl.resolve(path))
      ..followRedirects = false
      ..headers.addAll(const {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      })
      ..body = jsonEncode(body);
    if (sessionToken != null && sessionToken.isNotEmpty) {
      request.headers['X-Onaria-Member-Session'] = sessionToken;
    }
    return _httpClient
        .send(request)
        .then(http.Response.fromStream)
        .then((response) {
      AuthDiagnostics.record('POST', path, response.statusCode);
      return response;
    }).timeout(timeout);
  }

  static AuthenticatedMemberRegistration _readAuthenticatedRegistration(
    String body,
  ) {
    try {
      final decoded = jsonDecode(body);
      final member = decoded is Map<String, dynamic> ? decoded['member'] : null;
      if (member is! Map || member['id'] is! int || member['id'] < 1) {
        throw const FormatException('Invalid member response');
      }
      return AuthenticatedMemberRegistration(
        memberId: member['id'] as int,
        session: _readSession(body),
      );
    } catch (error) {
      if (error is FormatException) rethrow;
      throw const FormatException('Invalid member response');
    }
  }

  static MemberSession _readSession(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic> ||
        decoded['sessionToken'] is! String ||
        decoded['expiresInSeconds'] is! int) {
      throw const FormatException('Invalid member session response');
    }
    return MemberSession(
      token: decoded['sessionToken'] as String,
      expiresInSeconds: decoded['expiresInSeconds'] as int,
    );
  }

  static String? _readCode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['code'] is String) {
        return decoded['code'] as String;
      }
    } catch (_) {}
    return null;
  }

  static String _readError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {}
    return '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
  }

  void close() => _httpClient.close();
}

class MemberRegistration {
  const MemberRegistration({required this.memberId});
  final int memberId;
}

class MemberSession {
  const MemberSession({required this.token, required this.expiresInSeconds});
  final String token;
  final int expiresInSeconds;
}

class AuthenticatedMemberRegistration {
  const AuthenticatedMemberRegistration({
    required this.memberId,
    required this.session,
  });
  final int memberId;
  final MemberSession session;
}

class MemberApiException implements Exception {
  const MemberApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;
  @override
  String toString() => message;
}
