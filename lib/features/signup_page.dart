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
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/space_scaffold.dart';
import '../src/api/member_api_client.dart';
import '../src/api/provider_auth_api_client.dart';
import '../src/auth/apple_android_auth_client.dart';
import '../src/auth/google_login_service.dart';
import '../src/auth/kakao_login_service.dart';
import '../src/auth/naver_login_service.dart';

enum _IdentityFlowStage { idle, chooseAction, signUp, linkExisting }

class SignUpPage extends StatefulWidget {
  const SignUpPage(
      {super.key,
      this.credentialLoader,
      this.memberClientFactory,
      this.sessionStore});

  final MemberSessionStore? sessionStore;
  final Future<String> Function(String provider)? credentialLoader;
  final MemberApiClient Function()? memberClientFactory;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  MemberSessionStore get _sessions =>
      widget.sessionStore ?? MemberSessionStore.instance;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  String? _lastProvider;
  @override
  void initState() {
    super.initState();
    _loadLastProvider();
  }

  Future<void> _loadLastProvider() async {
    try {
      final provider = await SharedPreferencesAsync()
          .getString('onaria.last_login_provider.v1');
      if (mounted &&
          const {'naver', 'google', 'kakao', 'apple'}.contains(provider))
        setState(() => _lastProvider = provider);
    } catch (_) {/* Optional hint never gates authentication. */}
  }

  bool _busy = false;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _adultConfirmed = false;
  String? _pendingProvider;
  String? _pendingProviderCredential;
  _IdentityFlowStage _identityStage = _IdentityFlowStage.idle;

  @override
  Widget build(BuildContext context) => SpaceScaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BackButton(),
                  ),
                  if (_identityStage == _IdentityFlowStage.chooseAction) ...[
                    _accountChoiceCard(),
                    const SizedBox(height: 20),
                  ],
                  if (_identityStage == _IdentityFlowStage.linkExisting) ...[
                    _existingAccountLinkCard(),
                    const SizedBox(height: 20),
                  ],
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
                  if (_lastProvider != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                            '지난번에는 ${_providerLabel(_lastProvider)}로 로그인했어요. 사용할 수 없다면 이미 연결한 다른 방식이나 고객지원으로 확인해 주세요.')),
                  if (!kIsWeb &&
                      (_identityStage == _IdentityFlowStage.idle ||
                          _identityStage ==
                              _IdentityFlowStage.linkExisting)) ...[
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
                        '사용하던 로그인 방식을 선택해 주세요. 처음이라면 인증 후 시작할 수 있어요.',
                        style: TextStyle(color: AppTheme.of(context).muted),
                      ),
                    const SizedBox(height: 24),
                  ],
                  if (_pendingProvider != null &&
                      _identityStage == _IdentityFlowStage.signUp) ...[
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '시작하기 전 확인',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.of(context).ink,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() => _identityStage =
                                    _IdentityFlowStage.chooseAction),
                            child: const Text('기존 ONARIA 계정에 연결하기'),
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

  Widget _accountChoiceCard() {
    final provider = _providerLabel(_pendingProvider);
    return Container(
      key: const ValueKey('provider-account-choice'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.of(context).green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$provider 계정은 아직 ONARIA에 연결되어 있지 않아요',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.of(context).ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '기존 기록을 이어갈 방법을 선택해 주세요.',
            style: TextStyle(color: AppTheme.of(context).muted),
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: const ValueKey('link-existing-account'),
            onPressed: _busy
                ? null
                : () => setState(
                    () => _identityStage = _IdentityFlowStage.linkExisting),
            child: const Text('기존 ONARIA 계정에 연결'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('create-new-account'),
            onPressed: _busy
                ? null
                : () =>
                    setState(() => _identityStage = _IdentityFlowStage.signUp),
            child: const Text('새 계정 만들기'),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 로그인 방식으로 이미 이용한 적이 있다면 기존 계정에 연결해 주세요. 새 계정에는 기존 기록이 이어지지 않아요.',
            style: TextStyle(fontSize: 12, color: AppTheme.of(context).muted),
          ),
        ],
      ),
    );
  }

  Widget _existingAccountLinkCard() {
    final provider = _providerLabel(_pendingProvider);
    return Container(
      key: const ValueKey('existing-account-link'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.of(context).green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '기존 ONARIA 계정으로 본인 확인',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.of(context).ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$provider 계정을 연결하려면 위 로그인 버튼에서 예전에 ONARIA에 연결했던 다른 소셜 계정을 선택하세요. 인증이 끝나면 기존 회원에 안전하게 연결됩니다.',
            style: TextStyle(color: AppTheme.of(context).muted),
          ),
          const SizedBox(height: 8),
          Text(
            '같은 제공자의 다른 계정이나 회원 정보 입력만으로는 계정을 합치지 않습니다.',
            style: TextStyle(fontSize: 12, color: AppTheme.of(context).muted),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(
                    () => _identityStage = _IdentityFlowStage.chooseAction),
            child: const Text('다른 방법 선택'),
          ),
        ],
      ),
    );
  }

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
    if (_busy) return;
    if (widget.credentialLoader != null) {
      await _continueWithCredentialLoader('apple');
      return;
    }
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
      await _handleProviderCredential(
        provider: 'apple',
        credential: identityToken,
        client: client,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (mounted) {
        _showMessage(error.code == AuthorizationErrorCode.canceled
            ? 'Apple 인증을 취소했어요.'
            : 'Apple 인증을 완료하지 못했어요. 다시 시도해 주세요.');
      }
    } on MemberApiException {
      if (mounted) {
        _showMessage('서버에서 로그인을 확인하지 못했어요. 연결을 확인한 뒤 다시 시도해 주세요.');
      }
    } on FormatException {
      if (mounted) _showMessage('인증 요청을 완료하지 못했어요. 연결을 확인한 뒤 다시 시도해 주세요.');
    } catch (error) {
      if (mounted) {
        _showMessage('Apple 로그인을 완료하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      appleAndroid.close();
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_busy) return;
    if (widget.credentialLoader != null) {
      await _continueWithCredentialLoader('google');
      return;
    }
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
      await _handleProviderCredential(
        provider: 'google',
        credential: idToken,
        client: memberApi,
      );
    } on GoogleLoginException {
      if (mounted) _showMessage('인증 요청을 완료하지 못했어요. 연결을 확인한 뒤 다시 시도해 주세요.');
    } on MemberApiException {
      if (mounted) {
        _showMessage('서버에서 로그인을 확인하지 못했어요. 연결을 확인한 뒤 다시 시도해 주세요.');
      }
    } catch (_) {
      if (mounted) _showMessage('Google 로그인을 완료하지 못했어요. 다시 시도해 주세요.');
    } finally {
      memberApi.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueWithNaver() async {
    if (_busy) return;
    if (widget.credentialLoader != null) {
      await _continueWithCredentialLoader('naver');
      return;
    }
    final apiBaseUrl = ApiConfig.baseUrl;
    if (apiBaseUrl == null) {
      _showMessage('서버 설정이 필요해요. ${ApiConfig.setupHint}');
      return;
    }
    setState(() => _busy = true);
    final memberApi = MemberApiClient(baseUrl: apiBaseUrl);
    try {
      final accessToken = await NaverLoginService().authenticate();
      await _handleProviderCredential(
        provider: 'naver',
        credential: accessToken,
        client: memberApi,
      );
    } on NaverLoginException catch (error) {
      if (mounted) _showMessage(error.message);
    } on MemberApiException {
      if (mounted) {
        _showMessage('서버에서 로그인을 확인하지 못했어요. 연결을 확인한 뒤 다시 시도해 주세요.');
      }
    } catch (_) {
      if (mounted) _showMessage('네이버 로그인을 완료하지 못했어요. 다시 시도해 주세요.');
    } finally {
      memberApi.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueWithKakao() async {
    if (_busy) return;
    if (widget.credentialLoader != null) {
      await _continueWithCredentialLoader('kakao');
      return;
    }
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
      await _handleProviderCredential(
        provider: 'kakao',
        credential: auth.idToken,
        client: memberApi,
      );
    } on KakaoLoginException {
      if (mounted) _showMessage('인증 요청을 완료하지 못했어요. 연결을 확인한 뒤 다시 시도해 주세요.');
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

  Future<void> _continueWithCredentialLoader(String provider) async {
    if (_busy) return;
    setState(() => _busy = true);
    final client = widget.memberClientFactory?.call() ??
        MemberApiClient(baseUrl: ApiConfig.baseUrl!);
    try {
      final credential = await widget.credentialLoader!(provider);
      await _handleProviderCredential(
          provider: provider, credential: credential, client: client);
    } on MemberApiException {
      _showMessage('인증 요청을 완료하지 못했어요. 연결을 확인한 뒤 다시 시도해 주세요.');
    } catch (_) {
      _showMessage('로그인을 완료하지 못했어요. 다시 시도해 주세요.');
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleProviderCredential({
    required String provider,
    required String credential,
    required MemberApiClient client,
  }) async {
    if (!mounted) return;
    if (_identityStage == _IdentityFlowStage.linkExisting) {
      return _confirmExistingAccountAndLink(
        provider: provider,
        credential: credential,
        client: client,
      );
    }
    return _resolveProviderIdentity(
      provider: provider,
      credential: credential,
      client: client,
    );
  }

  Future<void> _confirmExistingAccountAndLink({
    required String provider,
    required String credential,
    required MemberApiClient client,
  }) async {
    final newProvider = _pendingProvider;
    final newCredential = _pendingProviderCredential;
    if (newProvider == null || newCredential == null) {
      if (mounted) {
        setState(() => _identityStage = _IdentityFlowStage.idle);
      }
      _showMessage('계정 연결 정보를 다시 확인해 주세요.');
      return;
    }
    if (provider == newProvider) {
      _showMessage(
        '현재 연결하려는 ${_providerLabel(provider)} 계정과 다른, 기존 ONARIA 로그인 수단을 선택해 주세요.',
      );
      return;
    }

    String existingSessionToken;
    try {
      final existingSession = await client.providerSession(
        provider: provider,
        credential: credential,
      );
      if (!mounted) return;
      existingSessionToken = existingSession.token;
    } on MemberApiException catch (error) {
      if (error.statusCode == 404 &&
          error.code == 'PROVIDER_IDENTITY_NOT_FOUND') {
        _showMessage(
          '이 ${_providerLabel(provider)} 계정은 기존 ONARIA 회원에 연결되어 있지 않아요. 예전에 ONARIA에서 사용하던 다른 로그인 수단을 선택해 주세요.',
        );
        return;
      }
      rethrow;
    }

    final linked = await client.linkProvider(
      provider: newProvider,
      credential: newCredential,
      sessionToken: existingSessionToken,
      reauthProvider: provider,
      reauthCredential: credential,
    );
    if (!mounted) return;
    final stored = await _acceptSession(
        provider: newProvider,
        token: linked.session.token,
        expiresInSeconds: linked.session.expiresInSeconds,
        memberId: linked.memberId);
    if (!mounted) return;
    setState(() {
      _identityStage = _IdentityFlowStage.idle;
      _pendingProvider = null;
      _pendingProviderCredential = null;
    });
    _showMessage(
      stored
          ? '기존 ONARIA 계정을 확인했어요. ${_providerLabel(newProvider)} 계정이 연결되었습니다.'
          : '계정 연결은 완료됐지만 기기에 로그인 정보를 저장하지 못했어요. 앱을 다시 열면 같은 방식으로 로그인해 주세요.',
    );
    Navigator.of(context).pop();
  }

  Future<void> _resolveProviderIdentity({
    required String provider,
    required String credential,
    required MemberApiClient client,
  }) async {
    try {
      final session = await client.providerSession(
        provider: provider,
        credential: credential,
      );
      if (!mounted) return;
      final stored = await _acceptSession(
          provider: provider,
          token: session.token,
          expiresInSeconds: session.expiresInSeconds);
      if (!mounted) return;
      _showMessage(stored
          ? '${_providerLabel(provider)} 로그인이 완료되었어요.'
          : '서버 인증은 완료됐지만 기기에 로그인 정보를 저장하지 못했어요. 앱을 다시 열면 같은 방식으로 로그인해 주세요.');
      Navigator.of(context).pop();
      return;
    } on MemberApiException catch (error) {
      if (error.statusCode != 404 ||
          error.code != 'PROVIDER_IDENTITY_NOT_FOUND') rethrow;
    }

    if (!mounted) return;
    setState(() {
      _pendingProvider = provider;
      _pendingProviderCredential = credential;
      _identityStage = _IdentityFlowStage.chooseAction;
    });
    // Present the next action immediately, including after a provider below
    // the fold was used. A snackbar must not cover the account choices.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  Future<void> _completeProviderSignUp() async {
    if (_busy) return;
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
    final client = widget.memberClientFactory?.call() ??
        MemberApiClient(baseUrl: apiBaseUrl);
    try {
      final registration = await client.providerSignUp(
        provider: provider,
        credential: credential,
        name: '',
        phone: '',
        churchName: '',
        adultConfirmed: _adultConfirmed,
      );
      if (!mounted) return;
      final stored = await _acceptSession(
          provider: provider,
          token: registration.session.token,
          expiresInSeconds: registration.session.expiresInSeconds,
          memberId: registration.memberId);
      if (!mounted) return;
      _showMessage(
        stored
            ? '${_providerLabel(provider)} 계정으로 회원가입이 완료되었어요.'
            : '회원가입은 완료됐지만 기기에 로그인 정보를 저장하지 못했어요. 같은 방식으로 다시 로그인해 주세요.',
      );
      Navigator.of(context).pop();
    } on MemberApiException catch (error) {
      if (error.statusCode == 409 &&
          const {'IDENTITY_ALREADY_REGISTERED', 'IDENTITY_EXISTS'}
              .contains(error.code)) {
        await _resolveProviderIdentity(
            provider: provider, credential: credential, client: client);
      } else if (mounted) {
        _showMessage('가입 결과를 확인하지 못했어요. 같은 로그인 방식으로 다시 확인해 주세요.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('가입 결과를 확인하지 못했어요. 같은 로그인 방식으로 다시 확인해 주세요.');
      }
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _acceptSession(
      {required String provider,
      required String token,
      required int expiresInSeconds,
      int? memberId}) async {
    final sessions = _sessions;
    sessions.set(token: token, expiresInSeconds: expiresInSeconds);
    var saved = await sessions.flush();
    if (memberId != null) {
      try {
        await MemberRegistrationStore().saveMemberId(memberId);
      } catch (_) {
        saved = false;
        // Server creation/link is complete. This optional cache never controls access.
      }
    }
    try {
      await SharedPreferencesAsync()
          .setString('onaria.last_login_provider.v1', provider);
    } catch (_) {/* Optional hint. */}
    return saved;
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
    _scrollController.dispose();
    super.dispose();
  }
}
