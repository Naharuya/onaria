import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../app/api_config.dart';
import '../app/app_theme.dart';
import '../app/google_auth_config.dart';
import '../app/kakao_auth_config.dart';
import '../app/member_registration_store.dart';
import '../app/member_session_store.dart';
import '../app/space_scaffold.dart';
import '../src/api/member_api_client.dart';
import '../src/api/provider_auth_api_client.dart';
import '../src/auth/google_login_service.dart';
import '../src/auth/kakao_login_service.dart';

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
                    'onaria 시작하기',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '계정을 연결하면 회원 확인과 회원탈퇴 같은 계정 기능을 안전하게 사용할 수 있어요.',
                    style: TextStyle(color: AppTheme.of(context).muted),
                  ),
                  const SizedBox(height: 24),
                  if (!kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.iOS) ...[
                    SignInWithAppleButton(
                      onPressed: _busy ? null : _continueWithApple,
                      text: 'Apple로 계속하기',
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (!kIsWeb) ...[
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        key: const ValueKey('kakao-signup'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE500),
                          foregroundColor: const Color(0xD9000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _busy ? null : _continueWithKakao,
                        child: const Text(
                          '카카오로 계속하기',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      key: const ValueKey('google-signup'),
                      onPressed: _busy ? null : _continueWithGoogle,
                      child: const Text('Google로 계속하기'),
                    ),
                    const SizedBox(height: 10),
                    const OutlinedButton(
                      onPressed: null,
                      child: Text('네이버로 계속하기 · 연결 준비 중'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '처음 이용하는 계정은 인증 후 아래 회원 정보를 입력해 가입을 완료합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.of(context).subtle,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
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
                            labelText: '이름',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: '전화번호',
                            hintText: '010-0000-0000',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) =>
                              RegExp(r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$')
                                      .hasMatch(value?.trim() ?? '')
                                  ? null
                                  : '휴대폰 번호를 확인해 주세요.',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _church,
                          maxLength: 100,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: '교회명',
                            prefixIcon: Icon(Icons.church_outlined),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : _pendingProviderCredential == null
                                  ? _submit
                                  : _completeProviderSignUp,
                          icon: const Icon(Icons.check),
                          label: Text(
                            _busy
                                ? '처리 중...'
                                : _pendingProviderCredential == null
                                    ? '회원가입'
                                    : _providerLabel(_pendingProvider) +
                                        '로 가입 완료',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [],
      );
      final identityToken = credential.identityToken;
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
    } catch (error) {
      if (mounted) {
        _showMessage('Apple 로그인 처리 오류: ${error.runtimeType}');
      }
    } finally {
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final apiBaseUrl = ApiConfig.baseUrl;
    if (apiBaseUrl == null) {
      _showMessage('서버 설정이 필요해요. ' + ApiConfig.setupHint);
      return;
    }

    setState(() => _busy = true);
    final client = MemberApiClient(baseUrl: apiBaseUrl);
    try {
      final registration = await client.signUp(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        churchName: _church.text.trim(),
      );
      await MemberRegistrationStore().saveMemberId(registration.memberId);
      if (!mounted) return;
      _showMessage('회원가입이 완료되었어요.');
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        _showMessage(
          error is MemberApiException
              ? error.message
              : '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.',
        );
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

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? '입력해 주세요.' : null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _church.dispose();
    super.dispose();
  }
}
