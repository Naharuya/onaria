import 'package:flutter/material.dart';
import '../app/api_config.dart';
import '../app/member_session_store.dart';
import '../src/api/provider_auth_api_client.dart';

class AccountMergePage extends StatefulWidget {
  const AccountMergePage(
      {super.key,
      required this.sessionStore,
      required this.apiClientFactory,
      required this.credentialLoader});
  final MemberSessionStore sessionStore;
  final ProviderAuthApiClient Function(Uri) apiClientFactory;
  final Future<String> Function(String) credentialLoader;
  @override
  State<AccountMergePage> createState() => _AccountMergePageState();
}

class _AccountMergePageState extends State<AccountMergePage> {
  String _source = 'naver';
  bool _busy = false, _confirming = false, _uncertain = false, _consent = false;
  String? _error, _preparedSession;
  AccountMergePlan? _plan;
  static const labels = {
    'naver': '네이버',
    'apple': 'Apple',
    'google': 'Google',
    'kakao': '카카오'
  };
  Future<void> _prepare() async {
    if (_busy || _uncertain) return;
    final token = widget.sessionStore.token, base = ApiConfig.baseUrl;
    if (token == null || base == null) {
      setState(() => _error = '로그인 상태를 다시 확인해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _plan = null;
      _consent = false;
    });
    final client = widget.apiClientFactory(base);
    try {
      final account = await client.account(token);
      if (!account.mergeAvailable ||
          account.currentProvider == null ||
          account.memberId == null) {
        throw const ProviderAuthApiException(
            '통합 기능을 준비 중이에요. 각 계정은 그대로 사용할 수 있어요.');
      }
      final targetProof =
          await widget.credentialLoader(account.currentProvider!);
      if (!mounted || widget.sessionStore.token != token) return;
      final sourceProof = await widget.credentialLoader(_source);
      if (!mounted || widget.sessionStore.token != token) return;
      final plan = await client.prepareMerge(token,
          reauthProvider: account.currentProvider!,
          reauthCredential: targetProof,
          sourceProvider: _source,
          sourceCredential: sourceProof);
      if (!mounted || widget.sessionStore.token != token) return;
      if (plan.targetId != account.memberId)
        throw const FormatException('Account changed');
      setState(() {
        _plan = plan;
        _preparedSession = token;
      });
    } catch (error) {
      if (mounted)
        setState(() => _error = switch (error) {
              ProviderAuthApiException(
                code: 'SAME_PROVIDER_ACCOUNT_CONFLICT'
              ) =>
                '같은 로그인 서비스의 서로 다른 계정은 합칠 수 없어요. 각 계정을 따로 사용해 주세요.',
              ProviderAuthApiException(code: 'MERGE_ALREADY_SAME_ACCOUNT') =>
                '이미 같은 ONARIA 계정에 연결되어 있어요.',
              ProviderAuthApiException(code: 'MERGE_SOURCE_NOT_REGISTERED') =>
                '이 소셜 계정은 아직 가입되지 않았어요. 통합하지 않고 별도로 가입할 수 있어요.',
              ProviderAuthApiException(statusCode: 503) =>
                '통합 기능을 지금 사용할 수 없어요. 기존 계정과 기록은 그대로 유지됩니다.',
              _ => '두 계정 확인을 완료하지 못했어요. 인증을 취소했거나 연결이 끊겼다면 다시 시도해 주세요.',
            });
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final plan = _plan, token = _preparedSession, base = ApiConfig.baseUrl;
    if (_busy ||
        !_consent ||
        _uncertain ||
        plan == null ||
        token == null ||
        base == null) return;
    if (widget.sessionStore.token != token ||
        !plan.expiresAt.isAfter(DateTime.now().toUtc())) {
      setState(() {
        _plan = null;
        _consent = false;
        _error = '확인 시간이 지났거나 계정이 바뀌었어요. 두 계정을 다시 확인해 주세요.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _confirming = true;
      _error = null;
    });
    final client = widget.apiClientFactory(base);
    try {
      final session = await client.confirmMerge(token, plan);
      if (widget.sessionStore.token != token) return;
      widget.sessionStore.set(
          token: session.token, expiresInSeconds: session.expiresInSeconds);
      final persisted = await widget.sessionStore.flush();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(persisted
                ? '계정을 통합했어요. 이전 기록은 계정 관리에서 확인할 수 있어요.'
                : '계정 통합은 완료됐지만 로그인 저장을 확인하지 못했어요. 다시 로그인해 주세요.')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      final uncertain = error is! ProviderAuthApiException ||
          error.statusCode == 503 ||
          (error.statusCode ?? 500) >= 500;
      setState(() {
        _uncertain = uncertain;
        _plan = null;
        _consent = false;
        _error = uncertain
            ? '통합 결과를 아직 확인할 수 없어요. 다시 로그인한 뒤 연결된 계정과 이전 기록을 확인해 주세요. 통합 버튼을 반복해서 누르지 않아도 됩니다.'
            : '통합하지 못했어요. 계정 상태가 바뀌었거나 확인 시간이 지났을 수 있어요. 두 계정을 다시 확인해 주세요.';
      });
    } finally {
      client.close();
      if (mounted)
        setState(() {
          _busy = false;
          _confirming = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return PopScope(
        canPop: !_confirming,
        child: Scaffold(
            appBar: AppBar(title: const Text('내 계정 통합')),
            body: ListView(padding: const EdgeInsets.all(20), children: [
              const Text('원할 때만 계정을 합쳐요.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                  '통합하지 않아도 각 계정으로 앱을 사용할 수 있어요. 이름이나 전화번호가 같아도 자동으로 합치지 않아요.'),
              const SizedBox(height: 16),
              if (plan == null && !_uncertain) ...[
                const Text('현재 계정의 로그인을 확인한 다음, 합칠 다른 계정에 로그인해 주세요.'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    initialValue: _source,
                    decoration:
                        const InputDecoration(labelText: '합칠 계정의 로그인 방법'),
                    items: labels.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: _busy
                        ? null
                        : (v) {
                            if (v != null) setState(() => _source = v);
                          }),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: _busy ? null : _prepare,
                    child: Text(_busy ? '계정 확인 중…' : '두 계정 확인하기')),
              ],
              if (plan != null) ...[
                const Text('통합 내용을 확인해 주세요.',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                    '통합 후 로그인 방법: ${plan.providers.map((p) => labels[p] ?? p).join(', ')}'),
                const SizedBox(height: 12),
                const Text(
                    '현재 계정을 유지하며 두 계정의 로그인 방법을 연결해요. 기존 로그인은 해제되고 이 기기는 새 로그인으로 연결돼요.'),
                const SizedBox(height: 12),
                const Text(
                    '기존 기록 원본은 덮어쓰지 않아요. 이전 계정의 기록은 계정 관리에서 따로 확인할 수 있어요. 이 기기에 없는 다른 기기의 기록을 자동으로 가져오지는 않아요.'),
                const SizedBox(height: 12),
                const Text(
                    '통합 후 계정을 다시 나누는 기능은 제공하지 않아요. 회원탈퇴하면 통합한 계정과 그 기록도 삭제 대상에 포함돼요.'),
                CheckboxListTile(
                    key: const ValueKey('merge-consent'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('위 내용을 확인했고 두 계정을 통합하는 데 동의해요.'),
                    value: _consent,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _consent = v ?? false)),
                FilledButton(
                    key: const ValueKey('merge-confirm'),
                    onPressed: _busy || !_consent ? null : _confirm,
                    child: Text(_confirming ? '통합 중…' : '동의하고 통합하기')),
                TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _plan = null;
                              _consent = false;
                              _preparedSession = null;
                            }),
                    child: const Text('통합하지 않고 돌아가기')),
              ],
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_error!, semanticsLabel: _error)),
              if (_uncertain)
                FilledButton(
                    onPressed: () {
                      widget.sessionStore.clear();
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('로그인 상태 정리 후 다시 로그인')),
              const SizedBox(height: 12),
              if (!_busy && !_uncertain)
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('지금은 통합하지 않기')),
            ])));
  }
}
