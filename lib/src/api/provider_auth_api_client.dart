import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../app/api_config.dart';
import 'auth_diagnostics.dart';

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
      throw ProviderAuthApiException(_readError(response.body),
          statusCode: response.statusCode);
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
      throw ProviderAuthApiException(_readError(response.body),
          statusCode: response.statusCode);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['providers'] is! List) {
      throw const FormatException('Invalid account response');
    }
    final member = decoded['member'];
    final memberId = member is Map && member['id'] is int && member['id'] > 0
        ? member['id'] as int
        : null;
    return AccountOverview(
      memberId: memberId,
      mergeAvailable: decoded['mergeAvailable'] == true,
      recordOwnerIds: _readOwnerIds(decoded, memberId),
      providers: (decoded['providers'] as List)
          .whereType<String>()
          .toList(growable: false),
      currentProvider: decoded['currentProvider'] is String
          ? decoded['currentProvider'] as String
          : null,
    );
  }

  Future<AccountMergePlan> prepareMerge(String sessionToken,
      {required String reauthProvider,
      required String reauthCredential,
      required String sourceProvider,
      required String sourceCredential}) async {
    final response = await _send('POST', '/v1/account/merge/prepare',
        sessionToken: sessionToken,
        body: {
          'reauthProvider': reauthProvider,
          'reauthCredential': reauthCredential,
          'sourceProvider': sourceProvider,
          'sourceCredential': sourceCredential,
        });
    if (response.statusCode != 201) {
      throw ProviderAuthApiException(_readError(response.body),
          statusCode: response.statusCode, code: _readCode(response.body));
    }
    return AccountMergePlan.fromJson(jsonDecode(response.body));
  }

  Future<MemberSession> confirmMerge(
      String sessionToken, AccountMergePlan plan) async {
    final response = await _send('POST', '/v1/account/merge/confirm',
        sessionToken: sessionToken,
        body: {'attemptToken': plan.attemptToken, 'consent': true});
    if (response.statusCode != 200) {
      throw ProviderAuthApiException(_readError(response.body),
          statusCode: response.statusCode, code: _readCode(response.body));
    }
    final value = jsonDecode(response.body);
    if (value is! Map<String, dynamic> ||
        value['completed'] != true ||
        value['targetId'] != plan.targetId ||
        value['sourceId'] != plan.sourceId ||
        jsonEncode(value['recordOwnerIds']) !=
            jsonEncode(plan.recordOwnerIds) ||
        value['sessionToken'] is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$')
            .hasMatch(value['sessionToken'] as String) ||
        value['expiresInSeconds'] is! int ||
        value['expiresInSeconds'] < 60 ||
        value['expiresInSeconds'] > 90 * 24 * 60 * 60) {
      throw const FormatException('Invalid merge confirmation');
    }
    return MemberSession(
        token: value['sessionToken'] as String,
        expiresInSeconds: value['expiresInSeconds'] as int);
  }

  static String? _readCode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map && value['code'] is String
          ? value['code'] as String
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> unlinkProvider(String sessionToken, String provider,
      {String? appleCredential,
      String? appleAuthorizationCode,
      String? reauthProvider,
      String? reauthCredential}) async {
    final response = await _send('DELETE', '/v1/account/providers/$provider',
        sessionToken: sessionToken,
        body: {
          if (appleCredential != null) 'appleCredential': appleCredential,
          if (appleAuthorizationCode != null)
            'appleAuthorizationCode': appleAuthorizationCode,
          if (reauthProvider != null) 'reauthProvider': reauthProvider,
          if (reauthCredential != null) 'reauthCredential': reauthCredential,
        });
    if (response.statusCode != 204) {
      throw ProviderAuthApiException(_readError(response.body),
          statusCode: response.statusCode);
    }
  }

  Future<void> logout(String sessionToken) async {
    final response = await _send('DELETE', '/v1/auth/provider/session',
        sessionToken: sessionToken);
    if (response.statusCode != 204) {
      throw ProviderAuthApiException(_readError(response.body),
          statusCode: response.statusCode);
    }
  }

  Future<void> deleteAccount(String sessionToken,
      {String? appleCredential,
      String? appleAuthorizationCode,
      String? reauthProvider,
      String? reauthCredential}) async {
    final response =
        await _send('DELETE', '/v1/account', sessionToken: sessionToken, body: {
      if (appleCredential != null) 'appleCredential': appleCredential,
      if (appleAuthorizationCode != null)
        'appleAuthorizationCode': appleAuthorizationCode,
      if (reauthProvider != null) 'reauthProvider': reauthProvider,
      if (reauthCredential != null) 'reauthCredential': reauthCredential,
    });
    if (response.statusCode != 204) {
      throw ProviderAuthApiException(_readError(response.body),
          statusCode: response.statusCode);
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
    try {
      return await _httpClient
          .send(request)
          .then(http.Response.fromStream)
          .then((response) {
        AuthDiagnostics.record(method, path, response.statusCode);
        return response;
      }).timeout(timeout);
    } catch (error) {
      final reason = switch (error) {
        TimeoutException() => 'timeout',
        HandshakeException() => 'tls',
        SocketException() => 'network',
        _ => 'transport',
      };
      AuthDiagnostics.failure(method, path, reason);
      rethrow;
    }
  }

  static List<int> _readOwnerIds(Map<String, dynamic> value, int? memberId) {
    if (!value.containsKey('recordOwnerIds'))
      return memberId == null ? const [] : [memberId];
    final raw = value['recordOwnerIds'];
    if (raw is! List ||
        memberId == null ||
        raw.isEmpty ||
        raw.length > 100 ||
        raw.any((id) => id is! int || id < 1) ||
        raw.toSet().length != raw.length ||
        !raw.contains(memberId)) {
      throw const FormatException('Invalid record ownership');
    }
    return List<int>.unmodifiable(raw);
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
  const ProviderAuthApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;
  @override
  String toString() => message;
}

class AccountOverview {
  const AccountOverview(
      {required this.providers,
      required this.currentProvider,
      this.memberId,
      this.mergeAvailable = false,
      this.recordOwnerIds = const []});
  final int? memberId;
  final bool mergeAvailable;
  final List<int> recordOwnerIds;
  final List<String> providers;
  final String? currentProvider;
}

class AccountMergePlan {
  const AccountMergePlan(
      {required this.attemptToken,
      required this.targetId,
      required this.sourceId,
      required this.providers,
      required this.recordOwnerIds,
      required this.expiresAt});
  final String attemptToken;
  final int targetId, sourceId;
  final List<String> providers;
  final List<int> recordOwnerIds;
  final DateTime expiresAt;
  static AccountMergePlan fromJson(dynamic value) {
    const supported = {'google', 'naver', 'apple', 'kakao'};
    if (value is! Map<String, dynamic> ||
        value['attemptToken'] is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$')
            .hasMatch(value['attemptToken'] as String) ||
        value['targetId'] is! int ||
        value['targetId'] < 1 ||
        value['sourceId'] is! int ||
        value['sourceId'] < 1 ||
        value['sourceId'] == value['targetId'] ||
        value['expiresAt'] is! int ||
        value['providers'] is! List ||
        value['recordOwnerIds'] is! List) {
      throw const FormatException('Invalid merge plan');
    }
    final providers = (value['providers'] as List).whereType<String>().toList();
    final owners = (value['recordOwnerIds'] as List).whereType<int>().toList();
    if (providers.length != (value['providers'] as List).length ||
        providers.isEmpty ||
        providers.toSet().length != providers.length ||
        providers.any((p) => !supported.contains(p)) ||
        owners.length != (value['recordOwnerIds'] as List).length ||
        owners.length > 100 ||
        owners.any((id) => id < 1) ||
        owners.toSet().length != owners.length ||
        !owners.contains(value['targetId']) ||
        !owners.contains(value['sourceId'])) {
      throw const FormatException('Invalid merge ownership');
    }
    return AccountMergePlan(
        attemptToken: value['attemptToken'] as String,
        targetId: value['targetId'] as int,
        sourceId: value['sourceId'] as int,
        providers: List.unmodifiable(providers),
        recordOwnerIds: List.unmodifiable(owners),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
            value['expiresAt'] as int,
            isUtc: true));
  }
}
