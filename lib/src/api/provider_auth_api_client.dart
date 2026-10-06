import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../app/api_config.dart';

class ProviderAuthApiClient {
  ProviderAuthApiClient(
      {required this.baseUrl,
      http.Client? httpClient,
      this.timeout = const Duration(seconds: 15)})
      : _httpClient = httpClient ?? http.Client();
  final Uri baseUrl;
  final http.Client _httpClient;
  final Duration timeout;

  Future<MemberSession> exchange(
      {required String provider,
      required String credential,
      String? nonce}) async {
    if (!const {'google', 'kakao', 'naver'}.contains(provider) ||
        credential.isEmpty ||
        credential.length > 8192) {
      throw const FormatException('Invalid provider credential');
    }
    final response = await _send('POST', '/v1/auth/provider/session', body: {
      'provider': provider,
      'credential': credential,
      if (nonce != null) 'nonce': nonce
    });
    if (response.statusCode != 201) {
      throw ProviderAuthApiException(_readError(response.body));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['sessionToken'] is! String ||
        decoded['expiresInSeconds'] is! int) {
      throw const FormatException('Invalid member session response');
    }
    return MemberSession(
        token: decoded['sessionToken'] as String,
        expiresInSeconds: decoded['expiresInSeconds'] as int);
  }

  Future<AccountOverview> account(String sessionToken) async {
    final response =
        await _send('GET', '/v1/account', sessionToken: sessionToken);
    if (response.statusCode != 200) {
      throw ProviderAuthApiException(_readError(response.body));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['providers'] is! List) {
      throw const FormatException('Invalid account response');
    }
    return AccountOverview(
      providers: (decoded['providers'] as List)
          .whereType<String>()
          .toList(growable: false),
      currentProvider: decoded['currentProvider'] is String
          ? decoded['currentProvider'] as String
          : null,
    );
  }

  Future<void> unlinkProvider(String sessionToken, String provider) async {
    final response = await _send('DELETE', '/v1/account/providers/$provider',
        sessionToken: sessionToken);
    if (response.statusCode != 204) {
      throw ProviderAuthApiException(_readError(response.body));
    }
  }

  Future<void> logout(String sessionToken) async {
    final response = await _send('DELETE', '/v1/auth/provider/session',
        sessionToken: sessionToken);
    if (response.statusCode != 204) {
      throw ProviderAuthApiException(_readError(response.body));
    }
  }

  Future<void> deleteAccount(String sessionToken) async {
    final response =
        await _send('DELETE', '/v1/account', sessionToken: sessionToken);
    if (response.statusCode != 204) {
      throw ProviderAuthApiException(_readError(response.body));
    }
  }

  Future<http.Response> _send(String method, String path,
      {Map<String, Object?>? body, String? sessionToken}) async {
    ApiConfig.requireSecureEndpoint(baseUrl);
    final request = http.Request(method, baseUrl.resolve(path))
      ..followRedirects = false;
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (sessionToken != null) {
      request.headers['X-Onaria-Member-Session'] = sessionToken;
    }
    return _httpClient
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);
  }

  static String _readError(String body) {
    try {
      final value = jsonDecode(body);
      if (value is Map<String, dynamic> && value['message'] is String) {
        return value['message'] as String;
      }
    } catch (_) {}
    return '회원 인증 요청을 처리하지 못했습니다.';
  }

  void close() => _httpClient.close();
}

class MemberSession {
  const MemberSession({required this.token, required this.expiresInSeconds});
  final String token;
  final int expiresInSeconds;
}

class ProviderAuthApiException implements Exception {
  const ProviderAuthApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AccountOverview {
  const AccountOverview(
      {required this.providers, required this.currentProvider});
  final List<String> providers;
  final String? currentProvider;
}
