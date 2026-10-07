import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/conversation_draft.dart';
import '../app/api_config.dart';
import '../app/member_session_store.dart';
import '../src/api/provider_auth_api_client.dart';
import '../src/auth/naver_login_service.dart';
import '../app/mind_card_store.dart';
import '../app/space_scaffold.dart';
import '../app/verse_history.dart';
import '../engagement/engagement_controller.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _busy = false;
  bool _hasSession = MemberSessionStore.instance.token != null;
  List<String> _providers = const [];
  String? _currentProvider;

  @override
  void initState() {
    super.initState();
    _refreshAccount();
  }

  Future<void> _refreshAccount() async {
    final token = MemberSessionStore.instance.token;
    final base = ApiConfig.baseUrl;
    if (token == null || base == null) {
      if (mounted)
        setState(() {
          _hasSession = false;
          _providers = const [];
          _currentProvider = null;
        });
      return;
    }
    final client = ProviderAuthApiClient(baseUrl: base);
    try {
      final account = await client.account(token);
      if (mounted)
        setState(() {
          _hasSession = true;
          _providers = account.providers;
          _currentProvider = account.currentProvider;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _hasSession = MemberSessionStore.instance.token != null;
          _providers = const [];
          _currentProvider = null;
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
    final token = MemberSessionStore.instance.token;
    final base = ApiConfig.baseUrl;
    if (token == null || base == null) return;
    setState(() => _busy = true);
    final client = ProviderAuthApiClient(baseUrl: base);
    try {
      await client.logout(token);
      MemberSessionStore.instance.clear();
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
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(providerCleared
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

  Future<void> _deleteAccount() async {
    final token = MemberSessionStore.instance.token;
    final base = ApiConfig.baseUrl;
    if (token == null || base == null) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('ONARIA 회원탈퇴'),
              content:
                  const Text('서버 회원정보와 연결된 소셜 계정을 삭제합니다. 이 작업은 되돌릴 수 없습니다.'),
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
    final client = ProviderAuthApiClient(baseUrl: base);
    try {
      await client.deleteAccount(token);
      MemberSessionStore.instance.clear();
      if (mounted) {
        setState(() => _providers = const []);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('회원탈퇴가 완료되었어요.')));
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원탈퇴를 완료하지 못했어요. 다시 시도해 주세요.')));
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlinkProvider(String provider) async {
    final token = MemberSessionStore.instance.token;
    final base = ApiConfig.baseUrl;
    if (token == null || base == null) return;
    final client = ProviderAuthApiClient(baseUrl: base);
    setState(() => _busy = true);
    try {
      await client.unlinkProvider(token, provider);
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
              title: Text('서버와 외부 AI'),
              subtitle: Text(
                  '대화를 보내면 입력 문장과 필요한 최근 맥락이 서버로 전송돼요. 외부 AI 사용은 서버 설정에 따라 달라져요. 앱의 로컬 기록 삭제는 서버의 사용량 기록이나 회원 정보를 삭제하지 않아요.')),
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
              '회원탈퇴는 서버의 회원정보를 삭제하는 별도 절차예요. 기기 기록 삭제나 앱 삭제만으로는 탈퇴되지 않아요.'),
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
                  : () => _delete(
                      '최근 말씀 선택 기록을',
                      () => SharedPreferencesAsync()
                          .remove(VerseHistory.storageKey)),
              child: const Text('최근 말씀 선택 기록 삭제')),
          const SizedBox(height: 20),

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
