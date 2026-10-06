import 'package:flutter/material.dart';
import '../app/api_config.dart';
import '../app/app_theme.dart';
import '../app/kakao_auth_config.dart';
import '../app/member_session_store.dart';
import '../app/space_scaffold.dart';
import '../src/api/provider_auth_api_client.dart';
import '../src/auth/kakao_login_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, this.loginOverride});
  final Future<void> Function()? loginOverride;
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _busy = false;
  bool get _signedIn => MemberSessionStore.instance.hasActiveSession;

  @override
  Widget build(BuildContext context) => SpaceScaffold(
          body: SafeArea(
              child: Center(
                  child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
            children: [
              const Align(alignment: Alignment.centerLeft, child: BackButton()),
              const SizedBox(height: 26),
              Text('계정',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                  _signedIn
                      ? 'ONARIA 계정이 연결되어 있어요.'
                      : '필요할 때만 계정을 연결하세요. 마음대화는 로그인 없이도 계속 사용할 수 있어요.',
                  style: TextStyle(
                      color: AppTheme.of(context).muted, height: 1.55)),
              const SizedBox(height: 36),
              if (!_signedIn && KakaoAuthConfig.enabled) ...[
                SizedBox(
                    height: 52,
                    child: FilledButton(
                      key: const ValueKey('kakao-login'),
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE500),
                          foregroundColor: const Color(0xD9000000),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: _busy ? null : _loginKakao,
                      child: Text(_busy ? '연결 중...' : '카카오로 계속하기',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    )),
                const SizedBox(height: 14),
                Text('로그인하면 계정 확인과 회원탈퇴 같은 계정 기능을 안전하게 사용할 수 있어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppTheme.of(context).subtle)),
              ],
              if (_signedIn)
                Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: AppTheme.of(context).panel,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.of(context).border)),
                    child: const Row(children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 12),
                      Expanded(child: Text('계정 연결됨'))
                    ])),
            ]),
      ))));

  Future<void> _loginKakao() async {
    final baseUrl = ApiConfig.baseUrl;
    if (baseUrl == null) {
      _message('서버 설정이 필요해요.');
      return;
    }
    setState(() => _busy = true);
    final api = ProviderAuthApiClient(baseUrl: baseUrl);
    try {
      if (widget.loginOverride != null) {
        await widget.loginOverride!();
      } else {
        await KakaoLoginService(api: api).login();
      }
      if (mounted) {
        setState(() {});
        _message('카카오 계정이 연결되었어요.');
      }
    } catch (error) {
      if (mounted) {
        _message(error is KakaoLoginException
            ? error.message
            : '카카오 로그인에 실패했어요. 다시 시도해 주세요.');
      }
    } finally {
      api.close();
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
