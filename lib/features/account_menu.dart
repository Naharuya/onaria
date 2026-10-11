import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app/api_config.dart';
import '../app/member_record_scope.dart';
import '../app/member_auth_controller.dart';
import '../app/member_session_store.dart';
import '../engagement/engagement_page.dart';
import '../engagement/journey/journey_page.dart';
import '../engagement/mini_games/cross_light/cross_light_page.dart';
import '../engagement/notifications/notification_settings_page.dart';
import '../src/api/provider_auth_api_client.dart';
import 'growth_page.dart';
import 'privacy_page.dart';
import 'saved_cards_page.dart';
import 'signup_page.dart';

class AccountMenuButton extends StatefulWidget {
  const AccountMenuButton({super.key, this.controller});
  final MemberAuthController? controller;

  @override
  State<AccountMenuButton> createState() => _AccountMenuButtonState();
}

class _AccountMenuButtonState extends State<AccountMenuButton>
    with WidgetsBindingObserver {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  late final _auth = widget.controller ??
      MemberAuthController(
        sessions: MemberSessionStore.instance,
        clientFactory: () {
          final base = ApiConfig.baseUrl;
          if (base == null) {
            throw const ProviderAuthApiException('서버 연결을 확인해 주세요.');
          }
          return ProviderAuthApiClient(baseUrl: base);
        },
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_auth.refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_auth.refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) _auth.dispose();
    super.dispose();
  }

  void _navigate(BuildContext menuContext, Widget page) {
    Navigator.of(menuContext).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _logout() async {
    try {
      final success = await _auth.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? '로그아웃했어요.' : '로그인 상태를 다시 확인해 주세요.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그아웃을 완료하지 못했어요. 다시 시도해 주세요.')));
      }
    }
  }

  void _open() {
    unawaited(_auth.refresh());
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (menuContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(menuContext).height * .85),
          child: AnimatedBuilder(
            animation: _auth,
            builder: (_, __) => ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                Semantics(
                  liveRegion: true,
                  child: ListTile(
                    key: const ValueKey('menu-auth-status'),
                    leading: Icon(_auth.state == MemberAuthState.signedIn
                        ? Icons.verified_user_outlined
                        : Icons.account_circle_outlined),
                    title: Text(_auth.label),
                    trailing: _auth.state == MemberAuthState.checking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : null,
                  ),
                ),
                if (_auth.state == MemberAuthState.signedOut)
                  ListTile(
                    key: const ValueKey('menu-login'),
                    leading: const Icon(Icons.login),
                    title: const Text('로그인'),
                    enabled: !_auth.busy,
                    onTap: () => _navigate(menuContext, const SignUpPage()),
                  ),
                if (_auth.state == MemberAuthState.unavailable)
                  ListTile(
                    title: const Text('상태 다시 확인'),
                    leading: const Icon(Icons.refresh),
                    enabled: !_auth.busy,
                    onTap: _auth.retry,
                  ),
                if (_auth.sessions.token != null ||
                    _auth.sessions.cleanupFailed)
                  ListTile(
                    key: const ValueKey('menu-logout'),
                    leading: const Icon(Icons.logout),
                    title: Text(_auth.busy
                        ? '로그아웃 중'
                        : _auth.sessions.cleanupFailed
                            ? '기기 정리 다시 시도'
                            : '로그아웃'),
                    enabled: !_auth.busy,
                    onTap: _logout,
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('계정 관리'),
                  subtitle: const Text('연결된 계정 · 회원탈퇴 · 개인정보'),
                  onTap: () => _navigate(menuContext, const PrivacyPage()),
                ),
                if (_auth.state == MemberAuthState.signedIn)
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('계정 연결'),
                    onTap: () => _navigate(menuContext, const SignUpPage()),
                  ),
                const Divider(),
                for (final item in <(String, IconData, Widget)>[
                  ('작은 성장 기록', Icons.spa_outlined, const GrowthPage()),
                  ('7일 마음의 여정', Icons.route_outlined, const JourneyPage()),
                  ('말씀과 작은 기록', Icons.book_outlined, const EngagementPage()),
                  ('십자가 미니게임', Icons.games_outlined, const CrossLightPage()),
                  (
                    '알림 설정',
                    Icons.notifications_outlined,
                    const NotificationSettingsPage()
                  ),
                  (
                    '저장된 마음 카드',
                    Icons.bookmarks_outlined,
                    const SavedCardsPage()
                  ),
                ])
                  ListTile(
                    leading: Icon(item.$2),
                    title: Text(item.$1),
                    enabled: !MemberRecordScope.instance.locked,
                    onTap: MemberRecordScope.instance.locked
                        ? null
                        : () => _navigate(menuContext, item.$3),
                  ),
                const Divider(),
                FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (_, snapshot) => ListTile(
                    key: const ValueKey('menu-app-info'),
                    leading: const Icon(Icons.info_outline),
                    title: const Text('앱 정보'),
                    subtitle: Text(snapshot.hasData
                        ? '버전 ${snapshot.data!.version} · 빌드 ${snapshot.data!.buildNumber}'
                        : snapshot.hasError
                            ? '앱 버전을 확인할 수 없어요.'
                            : '버전 확인 중'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: '메뉴',
        icon: const Icon(Icons.menu),
        onPressed: _open,
      );
}
