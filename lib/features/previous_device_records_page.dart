import 'package:flutter/material.dart';
import '../app/legacy_record_import.dart';
import '../app/space_scaffold.dart';

class PreviousDeviceRecordsPage extends StatefulWidget {
  const PreviousDeviceRecordsPage({super.key});
  @override
  State<PreviousDeviceRecordsPage> createState() =>
      _PreviousDeviceRecordsPageState();
}

class _PreviousDeviceRecordsPageState extends State<PreviousDeviceRecordsPage> {
  late Future<Map<String, int>> _counts = LegacyRecordImport().inventory();
  @override
  Widget build(BuildContext context) => SpaceScaffold(
        appBar: AppBar(title: const Text('이 기기의 이전 기록')),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('이전 기록은 그대로 보관하고 있어요.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
              '기존 기록에는 회원 소유 정보가 없어 현재 계정의 기록과 구분합니다. 첫 로그인 계정에 자동으로 가져오거나 삭제하지 않아요.'),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, int>>(
              future: _counts,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Column(children: [
                    const Text('기록 수량을 확인하지 못했어요.'),
                    TextButton(
                        onPressed: () => setState(
                            () => _counts = LegacyRecordImport().inventory()),
                        child: const Text('다시 확인'))
                  ]);
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '이전 마음카드 ${snapshot.data!['soul_bible.mind_cards.v1'] ?? 0}개'),
                      Text(
                          '이전 말씀 기록 ${snapshot.data!['onaria.recent_verses.v1'] ?? 0}개'),
                      const SizedBox(height: 16),
                      const Text(
                          '안전한 기기 소유 확인과 가져오기 절차를 준비 중이에요. 지금은 수량만 확인하며 기록 내용을 다른 계정에 보여주지 않아요.'),
                    ]);
              }),
        ])),
      );
}
