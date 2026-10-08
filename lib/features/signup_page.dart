import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/api_config.dart';
import '../app/app_theme.dart';
import '../app/google_auth_config.dart';
import '../app/kakao_auth_config.dart';
import '../app/member_registration_store.dart';
import '../app/member_session_store.dart';
import '../app/space_scaffold.dart';
import '../src/api/member_api_client.dart';
import '../src/api/provider_auth_api_client.dart';
import '../src/auth/apple_android_auth_client.dart';
import '../src/auth/google_login_service.dart';
import '../src/auth/kakao_login_service.dart';
import '../src/auth/naver_login_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _church = TextEditingController();

  bool _busy = false;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _adultConfirmed = false;
  String? _pendingProvider;
  String? _pendingProviderCredential;

  @override
  Widget build(BuildContext context) => SpaceScaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BackButton(),
                  ),
                  Icon(
                    Icons.auto_awesome,
                    color: AppTheme.of(context).green,
                    size: 38,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '로그인 또는 시작하기',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '사용하던 계정으로 마음의 기록을 이어가세요.',
                    style: TextStyle(color: AppTheme.of(context).muted),
                  ),
                  const SizedBox(height: 24),
                  if (!kIsWeb) ...[
                    _providerButton(
                      key: const ValueKey('apple-signup'),
                      label: 'Apple로 계속하기',
                      background: Colors.black,
                      foreground: Colors.white,
                      icon: Icons.apple,
                      onPressed: _continueWithApple,
                    ),
                    const SizedBox(height: 12),
                    _providerButton(
                      key: const ValueKey('google-signup'),
                      label: 'Google로 계속하기',
                      background: Colors.white,
                      foreground: const Color(0xFF1F1F1F),
                      outlined: true,
                      onPressed: _continueWithGoogle,
                    ),
                    const SizedBox(height: 12),
                    _providerButton(
                      key: const ValueKey('naver-signup'),
                      label: '네이버로 계속하기',
                      background: const Color(0xFF03C75A),
                      foreground: Colors.black,
                      onPressed: _continueWithNaver,
                    ),
                    const SizedBox(height: 12),
                    _providerButton(
                      key: const ValueKey('kakao-signup'),
                      label: '카카오로 계속하기',
                      background: const Color(0xFFFEE500),
                      foreground: const Color(0xD9000000),
                      onPressed: _continueWithKakao,
                    ),
                    const SizedBox(height: 16),
                    if (_busy) ...[
                      Semantics(
                        liveRegion: true,
                        child: const Text('인증을 진행하고 있어요. 잠시 기다려 주세요.'),
                      ),
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ] else
                      Text(
                        '가입할 때 사용한 계정을 선택해 주세요. 처음이라면 인증 후 가입을 이어갑니다.',
                        style: TextStyle(color: AppTheme.of(context).muted),
                      ),
                    const SizedBox(height: 24),
                  ],
                  if (_pendingProvider != null) ...[
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '회원 정보',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.of(context).ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _name,
                            maxLength: 40,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: '이름 (선택)',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: '전화번호 (선택)',
                              hintText: '+82 10 0000 0000',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) =>
                                (value?.trim().isEmpty ?? true) ||
                                        RegExp(r'^\+?[0-9][0-9 -]{6,19}$')
                                            .hasMatch(value?.trim() ?? '')
                                    ? null
                                    : '전화번호를 확인해 주세요.',
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _church,
                            maxLength: 100,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: '교회명 (선택)',
                              prefixIcon: Icon(Icons.church_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _adultConfirmed,
                            onChanged: _busy
                                ? null
                                : (value) => setState(
                                    () => _adultConfirmed = value ?? false),
                            title: const Text('만 18세 이상입니다. (필수)'),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _termsAccepted,
                            onChanged: _busy
                                ? null
                                : (value) => setState(
                                    () => _termsAccepted = value ?? false),
                            title: const Text('이용약관에 동의합니다. (필수)'),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          TextButton(
                            onPressed: () => launchUrl(
                                Uri.parse('https://onaria.ai.kr/terms'),
                                mode: LaunchMode.externalApplication),
                            child: const Text('이용약관 보기'),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _privacyAccepted,
                            onChanged: _busy
                                ? null
                                : (value) => setState(
                                    () => _privacyAccepted = value ?? false),
                            title: const Text('개인정보 처리 안내에 동의합니다. (필수)'),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          TextButton(
                            onPressed: () => launchUrl(
                                Uri.parse('https://onaria.ai.kr/privacy'),
                                mode: LaunchMode.externalApplication),
                            child: const Text('개인정보 처리 안내 보기'),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _busy ? null : _completeProviderSignUp,
                            icon: const Icon(Icons.check),
                            label: Text(
                              _busy
                                  ? '처리 중...'
                                  : '${_providerLabel(_pendingProvider)}로 가입 완료',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      );

  Widget _providerButton({
    required Key key,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onPressed,
    bool outlined = false,
    IconData? icon,
  }) =>
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: FilledButton(
          key: key,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            side: outlined ? const BorderSide(color: Color(0xFFDADCE0)) : null,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _busy ? null : onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 24),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );

  Future<void> _continueWithApple() async {
    final apiBaseUrl = ApiConfig.baseUrl;
    if (apiBaseUrl == null) {
      _showMessage('서버 설정이 필요해요. ' + ApiConfig.setupHint);
      return;
    }

    setState(() => _busy = true);
    final client = MemberApiClient(baseUrl: apiBaseUrl);
    final appleAndroid = AppleAndroidAuthClient(baseUrl: apiBaseUrl);
    try {
      final challenge = defaultTargetPlatform == TargetPlatform.android
          ? await appleAndroid.challenge()
          : null;
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [],
        state: challenge?.state,
        nonce: challenge?.nonce,
        webAuthenticationOptions: challenge == null
            ? null
            : WebAuthenticationOptions(
                clientId: challenge.clientId,
                redirectUri: challenge.redirectUri),
      );
      final identityToken = challenge == null
          ? credential.identityToken
          : challenge.checkedProof(
              returnedState: credential.state, token: credential.identityToken);
      if (identityToken == null || identityToken.isEmpty) {
        throw const FormatException('Apple identity token missing');
      }
      await _finishProviderAuthentication(
        provider: 'apple',
        credential: identityToken,
        client: client,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code != AuthorizationErrorCode.canceled && mounted) {
        _showMessage('Apple 인증 오류: ${error.code.name}');
      }
    } on MemberApiException catch (error) {
      if (mounted) {
        final suffix = error.statusCode == null ? '' : ' (${error.statusCode})';
        _showMessage('Apple 서버 인증 실패$suffix: ${error.message}');
      }
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) {
        _showMessage('Apple 로그인 처리 오류: ${error.runtimeType}');
      }
    } finally {
      appleAndroid.close();
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    final apiBaseUrl = ApiConfig.baseUrl;
    if (apiBaseUrl == null) {
      _showMessage('서버 설정이 필요해요. ${ApiConfig.setupHint}');
      return;
    }
    if (!GoogleAuthConfig.enabled) {
      _showMessage('Google 로그인 설정이 필요해요.');
      return;
    }

    setState(() => _busy = true);
    final memberApi = MemberApiClient(baseUrl: apiBaseUrl);
    try {
      final idToken = await GoogleLoginService().authenticate();
      await _finishProviderAuthentication(
        provider: 'google',
        credential: idToken,
        client: memberApi,
      );
    } on GoogleLoginException catch (error) {
      if (mounted) _showMessage(error.message);
    } on MemberApiException catch (error) {
      if (mounted) {
        final suffix = error.statusCode == null ? '' : ' (${error.statusCode})';
        _showMessage('Google 서버 인증 실패$suffix: ${error.message}');
      }
    } catch (_) {
      if (mounted) _showMessage('Google 로그인을 완료하지 못했어요. 다시 시도해 주세요.');
    } finally {
      memberApi.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueWithNaver() async {
    final apiBaseUrl = ApiConfig.baseUrl;
    if (apiBaseUrl == null) {
      _showMessage('서버 설정이 필요해요. ${ApiConfig.setupHint}');
      return;
    }
    setState(() => _busy = true);
    final memberApi = MemberApiClient(baseUrl: apiBaseUrl);
    try {
      final accessToken = await NaverLoginService().authenticate();
      await _finishProviderAuthentication(
        provider: 'naver',
        credential: accessToken,
        client: memberApi,
      );
    } on NaverLoginException catch (error) {
      if (mounted) _showMessage(error.message);
    } on MemberApiException catch (error) {
      if (mounted) {
        final suffix = error.statusCode == null ? '' : ' (${error.statusCode})';
        _showMessage('네이버 서버 인증 실패$suffix: ${error.message}');
      }
    } catch (_) {
      if (mounted) _showMessage('네이버 로그인을 완료하지 못했어요. 다시 시도해 주세요.');
    } finally {
      memberApi.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueWithKakao() async {
    final apiBaseUrl = ApiConfig.baseUrl;
    if (apiBaseUrl == null) {
      _showMessage('서버 설정이 필요해요. ' + ApiConfig.setupHint);
      return;
    }
    if (!KakaoAuthConfig.enabled) {
      _showMessage('카카오 앱 키 설정이 필요해요.');
      return;
    }

    setState(() => _busy = true);
    final providerApi = ProviderAuthApiClient(baseUrl: apiBaseUrl);
    final memberApi = MemberApiClient(baseUrl: apiBaseUrl);
    try {
      final auth = await KakaoLoginService(api: providerApi).authenticate();
      await _finishProviderAuthentication(
        provider: 'kakao',
        credential: auth.idToken,
        client: memberApi,
      );
    } on KakaoLoginException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('카카오 로그인을 완료하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      providerApi.close();
      memberApi.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishProviderAuthentication({
    required String provider,
    required String credential,
    required MemberApiClient client,
  }) async {
    try {
      final session = await client.providerSession(
        provider: provider,
        credential: credential,
      );
      MemberSessionStore.instance.set(
        token: session.token,
        expiresInSeconds: session.expiresInSeconds,
      );
      if (!mounted) return;
      _showMessage(_providerLabel(provider) + ' 로그인이 완료되었어요.');
      Navigator.of(context).pop();
      return;
    } on MemberApiException catch (error) {
      if (error.statusCode != 404) rethrow;
    }

    final currentSession = MemberSessionStore.instance.token;
    if (currentSession != null) {
      final linked = await client.linkProvider(
        provider: provider,
        credential: credential,
        sessionToken: currentSession,
      );
      MemberSessionStore.instance.set(
        token: linked.session.token,
        expiresInSeconds: linked.session.expiresInSeconds,
      );
      if (!mounted) return;
      _showMessage(_providerLabel(provider) + ' 계정이 현재 ONARIA 계정에 연결되었어요.');
      Navigator.of(context).pop();
      return;
    }

    if (!mounted) return;
    setState(() {
      _pendingProvider = provider;
      _pendingProviderCredential = credential;
    });
    _showMessage('처음 이용하시는 계정이에요. 아래 회원 정보를 입력해 가입을 완료해 주세요.');
  }

  Future<void> _completeProviderSignUp() async {
    if (!_adultConfirmed || !_termsAccepted || !_privacyAccepted) {
      _showMessage('만 18세 이상 여부를 확인하고 이용약관·개인정보 안내에 동의해 주세요.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final provider = _pendingProvider;
    final credential = _pendingProviderCredential;
    final apiBaseUrl = ApiConfig.baseUrl;
    if (provider == null || credential == null || apiBaseUrl == null) return;

    setState(() => _busy = true);
    final client = MemberApiClient(baseUrl: apiBaseUrl);
    try {
      final registration = await client.providerSignUp(
        provider: provider,
        credential: credential,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        churchName: _church.text.trim(),
        adultConfirmed: _adultConfirmed,
        sessionToken: MemberSessionStore.instance.token,
      );
      await MemberRegistrationStore().saveMemberId(registration.memberId);
      MemberSessionStore.instance.set(
        token: registration.session.token,
        expiresInSeconds: registration.session.expiresInSeconds,
      );
      if (!mounted) return;
      _showMessage(
        _providerLabel(provider) + ' 계정으로 회원가입이 완료되었어요.',
      );
      Navigator.of(context).pop();
    } on MemberApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('회원가입을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.');
      }
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  String _providerLabel(String? provider) => switch (provider) {
        'apple' => 'Apple',
        'kakao' => '카카오',
        'google' => 'Google',
        'naver' => '네이버',
        _ => '계정',
      };

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _church.dispose();
    super.dispose();
  }
}
