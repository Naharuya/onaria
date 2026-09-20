import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app/app_theme.dart';
import '../app/space_scaffold.dart';

class AppInfoPage extends StatefulWidget {
  const AppInfoPage({super.key});

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  bool _checking = false;

  Future<void> _checkForUpdates() async {
    if (_checking) return;
    setState(() => _checking = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _checking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('현재 설치된 앱의 버전 정보를 확인했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpaceScaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: '뒤로',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '앱 정보',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.of(context).panel,
                    border: Border.all(color: AppTheme.of(context).border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: FutureBuilder<PackageInfo>(
                    future: _packageInfo,
                    builder: (context, snapshot) {
                      final info = snapshot.data;
                      final loading = snapshot.connectionState != ConnectionState.done;
                      return Column(
                        children: [
                          _InfoRow(
                            label: '현재 버전',
                            value: loading ? '확인 중…' : (info?.version ?? '-'),
                          ),
                          const Divider(height: 32),
                          _InfoRow(
                            label: '빌드 번호',
                            value: loading ? '확인 중…' : (info?.buildNumber ?? '-'),
                          ),
                          const Divider(height: 32),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.system_update_outlined),
                            title: const Text('업데이트 확인'),
                            subtitle: const Text('설치된 앱의 버전 정보를 확인합니다.'),
                            trailing: _checking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: loading || _checking ? null : _checkForUpdates,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        Text(value, style: TextStyle(fontSize: 15, color: AppTheme.of(context).green, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
