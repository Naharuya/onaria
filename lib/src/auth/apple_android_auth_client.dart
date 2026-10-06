import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/api_config.dart';

class AppleAndroidChallenge {
  const AppleAndroidChallenge({
    required this.state,
    required this.nonce,
    required this.clientId,
    required this.redirectUri,
  });
  final String state;
  final String nonce;
  final String clientId;
  final Uri redirectUri;

  String checkedProof({
    required String? returnedState,
    required String? token,
  }) {
    if (returnedState != state ||
        token == null ||
        !RegExp(r'^apple_android\.[A-Za-z0-9_-]{43}$').hasMatch(token)) {
      throw const FormatException('Apple 인증 응답을 확인하지 못했어요. 다시 시도해 주세요.');
    }
    return token;
  }
}

class AppleAndroidAuthClient {
  AppleAndroidAuthClient({required this.baseUrl, http.Client? httpClient})
    : _client = httpClient ?? http.Client();
  final Uri baseUrl;
  final http.Client _client;

  Future<AppleAndroidChallenge> challenge() async {
    ApiConfig.requireSecureEndpoint(baseUrl);
    final request =
        http.Request(
            'POST',
            baseUrl.resolve('/v1/auth/apple/android/challenge'),
          )
          ..followRedirects = false
          ..headers['Accept'] = 'application/json';
    final response = await _client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const FormatException(
        '안드로이드 Apple 로그인 서버 연결을 준비 중이에요. 다른 방법으로 로그인해 주세요.',
      );
    }
    final value = jsonDecode(response.body);
    final id = RegExp(r'^[A-Za-z0-9_-]{43}$');
    if (value is! Map<String, dynamic> ||
        value['state'] is! String ||
        value['nonce'] is! String ||
        !id.hasMatch(value['state'] as String) ||
        !id.hasMatch(value['nonce'] as String) ||
        value['clientId'] is! String ||
        !RegExp(r'^[A-Za-z0-9.-]{3,256}$')
            .hasMatch(value['clientId'] as String) ||
        value['redirectUri'] !=
            baseUrl.resolve('/v1/auth/apple/android/callback').toString()) {
      throw const FormatException('Apple 로그인 연결 정보를 확인하지 못했어요.');
    }
    return AppleAndroidChallenge(
      state: value['state'] as String,
      nonce: value['nonce'] as String,
      clientId: value['clientId'] as String,
      redirectUri: Uri.parse(value['redirectUri'] as String),
    );
  }

  void close() => _client.close();
}
