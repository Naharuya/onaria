import 'dart:math';

import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../app/kakao_auth_config.dart';
import '../../app/member_session_store.dart';
import '../api/provider_auth_api_client.dart';

abstract interface class KakaoLoginGateway {
  Future<bool> isTalkInstalled();
  Future<String?> loginWithTalk({required String nonce});
  Future<String?> loginWithAccount({required String nonce});
}

class KakaoSdkLoginGateway implements KakaoLoginGateway {
  @override
  Future<bool> isTalkInstalled() => isKakaoTalkInstalled();
  @override
  Future<String?> loginWithTalk({required String nonce}) async =>
      (await UserApi.instance.loginWithKakaoTalk(nonce: nonce)).idToken;
  @override
  Future<String?> loginWithAccount({required String nonce}) async =>
      (await UserApi.instance.loginWithKakaoAccount(nonce: nonce)).idToken;
}

class KakaoLoginService {
  KakaoLoginService({
    required this.api,
    KakaoLoginGateway? gateway,
    MemberSessionStore? sessions,
    Random? random,
    bool? enabled,
  })  : gateway = gateway ?? KakaoSdkLoginGateway(),
        sessions = sessions ?? MemberSessionStore.instance,
        _random = random ?? Random.secure(),
        _enabled = enabled ?? KakaoAuthConfig.enabled;
  final ProviderAuthApiClient api;
  final KakaoLoginGateway gateway;
  final MemberSessionStore sessions;
  final Random _random;
  final bool _enabled;

  Future<KakaoCredential> authenticate() async {
    if (!_enabled) {
      throw const KakaoLoginException('카카오 로그인이 아직 설정되지 않았습니다.');
    }
    final nonce = List<int>.generate(
      32,
      (_) => _random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    String? idToken;
    if (await gateway.isTalkInstalled()) {
      try {
        idToken = await gateway.loginWithTalk(nonce: nonce);
      } on KakaoClientException catch (error) {
        if (error.reason == ClientErrorCause.cancelled) {
          throw const KakaoLoginException('카카오 로그인이 취소되었습니다.');
        }
        idToken = null;
      } catch (_) {
        idToken = null;
      }
    }
    try {
      idToken ??= await gateway.loginWithAccount(nonce: nonce);
    } catch (error) {
      throw KakaoLoginException('카카오 인증 오류: $error');
    }
    if (idToken == null || idToken.isEmpty) {
      throw const KakaoLoginException('카카오 인증 정보를 확인하지 못했습니다.');
    }
    return KakaoCredential(idToken: idToken, nonce: nonce);
  }

  Future<void> login() async {
    final credential = await authenticate();
    final memberSession = await api.exchange(
      provider: 'kakao',
      credential: credential.idToken,
      nonce: credential.nonce,
    );
    sessions.set(
      token: memberSession.token,
      expiresInSeconds: memberSession.expiresInSeconds,
    );
  }
}

class KakaoLoginException implements Exception {
  const KakaoLoginException(this.message);
  final String message;
  @override
  String toString() => message;
}

class KakaoCredential {
  const KakaoCredential({required this.idToken, required this.nonce});
  final String idToken;
  final String nonce;
}
