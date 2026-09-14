import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../app/space_scaffold.dart';
import '../app/api_config.dart';
import '../src/api/member_api_client.dart';

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

  @override
  Widget build(BuildContext context) => SpaceScaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  const Align(alignment: Alignment.centerLeft, child: BackButton()),
                  Icon(Icons.auto_awesome, color: AppTheme.of(context).green, size: 38),
                  const SizedBox(height: 18),
                  Text('onaria 시작하기', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('회원가입은 선택이에요. 가입하지 않아도 대화와 기록을 사용할 수 있어요. 현재 가입은 회원 정보 등록이며, 로그인이나 기기 간 기록 동기화를 제공하지 않아요.', style: TextStyle(color: AppTheme.of(context).muted)),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('가입하지 않고 돌아가기')),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('회원 정보', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.of(context).ink)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _name,
                        maxLength: 40,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: '이름', prefixIcon: Icon(Icons.person_outline)),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: '전화번호', hintText: '010-0000-0000', prefixIcon: Icon(Icons.phone_outlined)),
                        validator: (value) => RegExp(r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$').hasMatch(value?.trim() ?? '')
                            ? null : '휴대폰 번호를 확인해 주세요.',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _church,
                        onFieldSubmitted: (_) => _submit(),
                        maxLength: 100,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(labelText: '교회명 (선택)', prefixIcon: Icon(Icons.church_outlined)),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(onPressed: _busy ? null : _submit, icon: const Icon(Icons.check), label: Text(_busy ? '가입 중...' : '회원가입')),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  String? _required(String? value) => value == null || value.trim().isEmpty ? '입력해 주세요.' : null;
  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final apiBaseUrl = ApiConfig.baseUrl;
    if (apiBaseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 설정이 필요해요. ${ApiConfig.setupHint}')),
      );
      return;
    }
    setState(() => _busy = true);
    final client = MemberApiClient(baseUrl: apiBaseUrl);
    try {
      await client.signUp(name: _name.text.trim(), phone: _phone.text.trim(), churchName: _church.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었어요.')));
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          error is MemberApiException ? error.message : '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.',
        )));
      }
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() { _name.dispose(); _phone.dispose(); _church.dispose(); super.dispose(); }
}
