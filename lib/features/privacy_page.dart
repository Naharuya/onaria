import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/conversation_draft.dart';
import '../app/api_config.dart';
import '../app/ai_consent.dart';
import '../app/member_session_store.dart';
import '../app/member_registration_store.dart';
import '../app/member_record_cleanup.dart';
import 'previous_device_records_page.dart';
import 'account_merge_page.dart';
import 'merged_records_page.dart';
import '../src/auth/google_login_service.dart';
import '../src/auth/kakao_login_service.dart';
import '../src/api/provider_auth_api_client.dart';
import '../src/auth/apple_android_auth_client.dart';
import '../src/auth/naver_login_service.dart';
import '../app/mind_card_store.dart';
import '../app/space_scaffold.dart';
import '../app/verse_history.dart';
import '../engagement/engagement_controller.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage(
      {super.key,
      this.sessionStore,
      this.apiClientFactory,
      this.registrationStore,
      this.reauthenticationCredential,
      this.appleDeletionCredential});
  final Future<String> Function(String provider)? reauthenticationCredential;
  final MemberSessionStore? sessionStore;
  final MemberRegistrationStore? registrationStore;
  final Future<AuthorizationCredentialAppleID> Function()?
      appleDeletionCredential;
  final ProviderAuthApiClient Function(Uri)? apiClientFactory;
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _busy = false;
  late bool _hasSession;
  MemberSessionStore get _sessionStore =>
      widget.sessionStore ?? MemberSessionStore.instance;
  ProviderAuthApiClient _apiClient(Uri base) =>
      widget.apiClientFactory?.call(base) ??
      ProviderAuthApiClient(baseUrl: base);
  List<String> _providers = const [];
  String? _currentProvider;
  bool _mergeAvailable = false;
  List<int> _recordOwnerIds = const [];

  @override
  void initState() {
    super.initState();
    _hasSession = _sessionStore.token != null;
    _refreshAccount();
  }

  Future<void> _refreshAccount() async {
    final token = _sessionStore.token;
    final base = ApiConfig.baseUrl;
    if (token == null || base == null) {
      if (mounted)
        setState(() {
          _hasSession = false;
          _providers = const [];
          _currentProvider = null;
          _mergeAvailable = false;
          _recordOwnerIds = const [];
        });
      return;
    }
    final client = _apiClient(base);
    try {
      final account = await client.account(token);
      if (mounted)
        setState(() {
          _hasSession = true;
          _providers = account.providers;
          _currentProvider = account.currentProvider;
          _mergeAvailable = account.mergeAvailable;
          _recordOwnerIds = account.recordOwnerIds;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _hasSession = _sessionStore.token != null;
          _providers = const [];
          _currentProvider = null;
          _mergeAvailable = false;
          _recordOwnerIds = const [];
        });
    } finally {
      client.close();
    }
  }

  String _providerLabel(String provider) => switch (provider) {
        'apple' => 'Apple',
        'kakao' => '카카오',
        'google' => 'Google',
        'naver' => '네이버',
        _ => provider,
      };

  Future<void> _logout() async {
    final token = _sessionStore.token;
    final base = ApiConfig.baseUrl;
    if (token == null || base == null) return;
    setState(() => _busy = true);
    final client = _apiClient(base);
    try {
      await client.logout(token);
      if (_sessionStore.token != token) return;
      _sessionStore.clear();
      var providerCleared = true;
      try {
        await NaverLoginService().signOut();
      } on NaverLoginException {
        // The server session is already revoked. Keep the app logged out;
        // the next Naver login retries SDK cleanup before authenticating.
        providerCleared = false;
      }
      if (mounted) {
        setState(() {
          _hasSession = false;
          _providers = const [];
          _currentProvider = null;
          _mergeAvailable = false;
          _recordOwnerIds = const [];
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(providerCleared
                ? '로그아웃했어요.'
                : 'ONARIA에서 로그아웃했어요. 네이버 인증 상태는 다음 로그인 때 다시 정리합니다.')));
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('로그아웃을 완료하지 못했어요.')));
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<AuthorizationCredentialAppleID> _appleDeletionCredential() async {
    final base = ApiConfig.baseUrl;
    if (base == null || kIsWeb)
      throw const ProviderAuthApiException('Apple 본인 확인을 사용할 수 없어요.');
    final android = AppleAndroidAuthClient(baseUrl: base);
    try {
      final challenge = defaultTargetPlatform == TargetPlatform.android
          ? await android.challenge()
          : null;
      final credential = await SignInWithApple.getAppleIDCredential(
          scopes: const [],
          state: challenge?.state,
          nonce: challenge?.nonce,
          webAuthenticationOptions: challenge == null
              ? null
              : WebAuthenticationOptions(
                  clientId: challenge.clientId,
                  redirectUri: challenge.redirectUri));
      if (challenge != null) {
        challenge.checkedProof(
            returnedState: credential.state, token: credential.identityToken);
      }
      if (credential.identityToken == null ||
          credential.authorizationCode.isEmpty) {
        throw const ProviderAuthApiException('Apple 본인 확인을 완료하지 못했어요.');
      }
      return credential;
    } finally {
      android.close();
    }
  }

  Future<void> _deleteAccount() async {
    final token = _sessionStore.token;
    final base = ApiConfig.baseUrl;
    if (token == null || base == null) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('ONARIA 회원탈퇴'),
              content: const Text(
                  '본인 확인 후 서버 회원정보·연결 로그인 수단과 이 회원의 기기 기록·초안을 삭제합니다. 통합한 계정의 기록도 삭제 대상입니다. 다른 회원과 소유 정보가 없는 이전 기기 기록은 삭제하지 않습니다. 백업·운영 기록은 별도 처리 기준을 따릅니다. 이 작업은 되돌릴 수 없습니다.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('회원탈퇴')),
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final client = _apiClient(base);
    var deletionRequested = false;
    try {
      // Fail closed if linked identities cannot be freshly verified. Cached UI
      // data may be empty after a failed initial load.
      final account = await client.account(token);
      if (account.memberId == null || _sessionStore.token != token)
        throw const FormatException('Account identity unavailable');
      final ownerId = account.memberId!;
      final apple = account.providers.contains('apple')
          ? await (widget.appleDeletionCredential?.call() ??
              _appleDeletionCredential())
          : null;
      final proofProvider = apple == null ? account.currentProvider : 'apple';
      if (proofProvider == null)
        throw const FormatException('Missing provider');
      final proof =
          apple?.identityToken ?? await _reauthenticate(proofProvider);
      if (!mounted || _sessionStore.token != token) return;
      deletionRequested = true;
      await client.deleteAccount(token,
          reauthProvider: proofProvider,
          reauthCredential: proof,
          appleCredential: apple?.identityToken,
          appleAuthorizationCode: apple?.authorizationCode);
      var recordsCleared = false;
      try {
        final cleanup = MemberRecordCleanup();
        recordsCleared = true;
        final owners =
            account.recordOwnerIds.isEmpty ? [ownerId] : account.recordOwnerIds;
        await cleanup.markServerDeletedMany(owners);
        for (final id in owners) {
          recordsCleared = await cleanup.retry(id) && recordsCleared;
        }
      } catch (_) {
        /* Server deletion remains complete; local cleanup is separate. */
      }
      final sameSession = _sessionStore.token == token;
      if (sameSession) _sessionStore.clear();
      final sessionCleared = !sameSession || await _sessionStore.flush();
      // A completed server deletion must not be reported as failed if local
      // metadata or member-scoped record cleanup fails. Legacy/other owners remain.
      var localMetadataCleared = true;
      try {
        if (sameSession)
          await (widget.registrationStore ?? MemberRegistrationStore()).clear();
      } catch (_) {
        localMetadataCleared = false;
      }
      if (mounted) {
        setState(() {
          _hasSession = false;
          _providers = const [];
          _currentProvider = null;
          _mergeAvailable = false;
          _recordOwnerIds = const [];
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                localMetadataCleared && recordsCleared && sessionCleared
                    ? '회원탈퇴가 완료되었어요.'
                    : '서버 회원탈퇴는 완료됐어요. 이 회원의 기기 정보 정리는 다시 확인해 주세요.')));
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(deletionRequested
                ? '회원탈퇴 처리 결과를 확인하지 못했어요. 일부 로그인이 해제됐을 수 있으니 계정 상태를 확인해 주세요.'
                : '회원탈퇴를 완료하지 못했어요. 다시 시도해 주세요.')));
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlinkProvider(String provider) async {
    final token = _sessionStore.token;
    final base = ApiConfig.baseUrl;
    if (token == null || base == null) return;
    final client = _apiClient(base);
    setState(() => _busy = true);
    try {
      final account = await client.account(token);
      final current = account.currentProvider;
      if (current == null || _sessionStore.token != token)
        throw const FormatException('Account changed');
      final proof = await _reauthenticate(current);
      final apple =
          provider == 'apple' ? await _appleDeletionCredential() : null;
      if (!mounted || _sessionStore.token != token) return;
      await client.unlinkProvider(token, provider,
          reauthProvider: current,
          reauthCredential: proof,
          appleCredential: apple?.identityToken,
          appleAuthorizationCode: apple?.authorizationCode);
      await _refreshAccount();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_providerLabel(provider)} 연결을 해제했어요.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error is ProviderAuthApiException
                ? error.message
                : '계정 연결 해제를 완료하지 못했어요.')));
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _reauthenticate(String provider) async {
    if (widget.reauthenticationCredential != null)
      return widget.reauthenticationCredential!(provider);
    switch (provider) {
      case 'google':
        return GoogleLoginService().authenticate();
      case 'naver':
        return NaverLoginService().authenticate();
      case 'apple':
        return (await _appleDeletionCredential()).identityToken ??
            (throw const FormatException('Missing proof'));
      case 'kakao':
        final client = _apiClient(ApiConfig.baseUrl!);
        try {
          return (await KakaoLoginService(api: client).authenticate()).idToken;
        } finally {
          client.close();
        }
      default:
        throw const FormatException('Unsupported provider');
    }
  }

  Future<void> _delete(String name, Future<void> Function() action) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('$name 삭제할까요?'),
                content: const Text(
                    '이 기기의 해당 기록만 삭제하며 되돌릴 수 없어요. 서버 회원 정보와 다른 앱 기록은 그대로 남아요.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('삭제'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$name 삭제했어요.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제를 완료하지 못했어요. 다시 시도해 주세요.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engagement = EngagementScope.maybeOf(context);
    return SpaceScaffold(
        appBar: AppBar(title: const Text('계정과 기록 관리')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('어디에 저장되나요?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const ListTile(
              title: Text('이 기기'),
              subtitle: Text(
                  '저장한 마음카드에는 감정·강도·선택한 실천과 대화 요약이 포함될 수 있어요. 임시 문장은 저장을 선택했을 때만 보관하며, 전체 대화 원문을 자동 보관하지 않아요. 말씀·여정·실천 기록도 기기에 남아요.')),
          const ListTile(
              title: Text('서버와 외부 AI'), subtitle: Text(AiConsent.disclosure)),
          TextButton.icon(
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('외부 AI 전송 허용 철회'),
            onPressed: _busy
                ? null
                : () async {
                    await AiConsent.withdraw();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            '허용을 철회했어요. 다음 대화 전송 전에 다시 확인해요. 이미 전송된 데이터의 삭제는 개인정보처리방침을 확인해 주세요.')));
                  },
          ),
          const ListTile(
              title: Text('음성과 의견'),
              subtitle: Text(
                  '음성 입력은 기기의 음성 인식 서비스를 사용하며 서비스 설정에 따라 네트워크를 사용할 수 있어요. 말씀 듣기는 기기 음성 엔진을 사용해요. 의견 보내기는 선택한 평가와 이유만 전송하며 대화 원문을 첨부하지 않아요.')),
          const Text(
              '공유 기기에서는 임시 저장을 끄고 사용 후 필요한 기록을 삭제해 주세요. 공유한 이미지와 다른 곳에 보관한 사본은 여기서 삭제되지 않아요.'),
          const SizedBox(height: 16),
          const Text('회원 정보와 계정',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text(
              '회원탈퇴는 본인 확인 후 서버 회원정보와 이 회원의 기기 기록·초안을 정리해요. 다른 회원과 소유 정보가 없는 이전 기기 기록은 보존해요. 기기 기록 삭제나 앱 삭제만으로는 탈퇴되지 않아요.'),
          const SizedBox(height: 10),
          if (_hasSession) ...[
            const SizedBox(height: 8),
            if (_providers.isEmpty)
              const Text('로그인 상태입니다. 연결된 계정 정보를 불러오지 못해도 로그아웃할 수 있어요.'),
            if (_providers.isNotEmpty)
              const Text('연결된 로그인 계정',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            if (_providers.isNotEmpty)
              ..._providers.map((provider) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_providerLabel(provider)),
                    trailing: provider == _currentProvider
                        ? const Text('현재 로그인', style: TextStyle(fontSize: 12))
                        : _providers.length > 1
                            ? TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _unlinkProvider(provider),
                                child: const Text('연결 해제'))
                            : const Text('유지 필요',
                                style: TextStyle(fontSize: 12)),
                  )),
            ListTile(
              key: const ValueKey('optional-account-merge'),
              leading: const Icon(Icons.merge_outlined),
              title: const Text('내 계정 통합 (선택)'),
              subtitle: Text(_mergeAvailable
                  ? '두 계정에 로그인한 뒤 원하는 경우에만 합쳐요.'
                  : '통합 기능을 준비 중이에요. 지금은 각 계정을 그대로 사용할 수 있어요.'),
              enabled: !_busy && _mergeAvailable,
              onTap: !_busy && _mergeAvailable
                  ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => AccountMergePage(
                          sessionStore: _sessionStore,
                          apiClientFactory: _apiClient,
                          credentialLoader: _reauthenticate)))
                  : null,
            ),
            if (_recordOwnerIds.length > 1)
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('통합한 계정의 이전 기록'),
                subtitle: const Text('원본을 유지한 채 이 기기에 남은 기록을 확인해요.'),
                onTap: _busy
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => MergedRecordsPage(
                            sessionStore: _sessionStore,
                            apiClientFactory: _apiClient))),
              ),
            OutlinedButton.icon(
                onPressed: _busy ? null : _logout,
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃')),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const ValueKey('account-deletion'),
              onPressed: _busy ? null : _deleteAccount,
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('회원탈퇴'),
            ),
          ] else ...[
            const Text('로그인하면 연결된 계정 관리와 회원탈퇴를 사용할 수 있어요.'),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _delete('임시 문장을', () async {
                        await SharedPreferencesAsync()
                            .setBool(ConversationDraft.autoSaveKey, false);
                        await ConversationDraft.delete();
                      }),
              child: const Text('자동 복구 끄고 임시 문장 삭제')),
          OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _delete('마음카드와 관련 실천 기록을', MindCardStore().deleteAll),
              child: const Text('마음카드·실천 기록 전체 삭제')),
          if (engagement != null) ...[
            OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _delete('저장한 말씀을', engagement.clearSavedVerses),
                child: const Text('저장한 말씀 삭제')),
            OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _delete('7일 여정을', engagement.deleteJourney),
                child: const Text('7일 여정 기록 삭제')),
          ],
          OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _delete('최근 말씀 선택 기록을', VerseHistory.delete),
              child: const Text('최근 말씀 선택 기록 삭제')),
          const SizedBox(height: 20),
          TextButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const PreviousDeviceRecordsPage())),
              child: const Text('이 기기의 이전 기록 안내')),
          TextButton(
              onPressed: () async {
                try {
                  if (!await launchUrl(
                      Uri.parse('https://onaria.ai.kr/account-deletion'),
                      mode: LaunchMode.externalApplication)) {
                    throw StateError('unavailable');
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('계정 삭제 안내를 열지 못했어요.')));
                  }
                }
              },
              child: const Text('웹에서 계정 삭제 안내 보기')),
          TextButton(
              onPressed: () async {
                try {
                  if (!await launchUrl(
                      Uri.parse('https://onaria.ai.kr/privacy'),
                      mode: LaunchMode.externalApplication)) {
                    throw StateError('unavailable');
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('개인정보 안내를 열지 못했어요.')));
                  }
                }
              },
              child: const Text('공식 개인정보 안내 보기')),
        ]));
  }
}
