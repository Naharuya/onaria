import 'package:flutter/material.dart';
import '../app/api_config.dart';
import '../app/asset_loader.dart';
import '../app/member_session_store.dart';
import '../app/member_record_scope.dart';
import '../app/merged_record_reader.dart';
import '../src/api/provider_auth_api_client.dart';
import '../src/verses/verse_repository.dart';
import '../src/verses/verse_models.dart';
import '../src/conversation/conversation_models.dart';

class MergedRecordsPage extends StatefulWidget {
  const MergedRecordsPage(
      {super.key, required this.sessionStore, required this.apiClientFactory});
  final MemberSessionStore sessionStore;
  final ProviderAuthApiClient Function(Uri) apiClientFactory;
  @override
  State<MergedRecordsPage> createState() => _MergedRecordsPageState();
}

class _MergedRecordsPageState extends State<MergedRecordsPage> {
  List<MergedRecordArchive>? _archives;
  Map<String, BibleVerse> _verses = {};
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final base = ApiConfig.baseUrl,
        access = MemberRecordScope.instance.capture(),
        token = widget.sessionStore.token;
    if (base == null) {
      setState(() => _error = '서버 연결을 확인해 주세요.');
      return;
    }
    final client = widget.apiClientFactory(base);
    try {
      final archives = await MergedRecordReader(
              client: client, sessions: widget.sessionStore)
          .load();
      final verses =
          await VerseRepository(loader: const FlutterVerseAssetLoader())
              .loadAll();
      if (!mounted || !access.current || widget.sessionStore.token != token)
        return;
      setState(() {
        _archives = archives;
        _verses = {for (final v in verses) v.id: v};
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = '계정 소유권이나 기록을 확인하지 못했어요. 다시 로그인한 뒤 확인해 주세요.');
    } finally {
      client.close();
    }
  }

  List<Widget> _verseWidgets(Iterable<String> ids) => ids.map((id) {
        final verse = _verses[id];
        return ListTile(
            title: Text(verse?.reference ?? '보존된 말씀'),
            subtitle:
                Text(verse?.text ?? '이 말씀은 현재 목록에서 찾지 못했어요. 원본 기록은 유지됩니다.'));
      }).toList();
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('통합한 계정의 이전 기록')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text(
            '이 기기에 남아 있는 원본 기록이에요. 새 기록과 별도로 보존하며 여기서는 수정하거나 덮어쓰지 않아요. 다른 기기의 기록은 그 기기에서 로그인한 뒤 확인해 주세요.'),
        if (_error != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
        if (_archives == null && _error == null)
          const Center(child: CircularProgressIndicator()),
        if (_archives != null)
          for (final entry in _archives!.indexed)
            ExpansionTile(title: Text('이전 계정 ${entry.$1 + 1}'), children: [
              if (entry.$2.cards.isEmpty)
                const ListTile(title: Text('이 기기에 저장된 마음카드가 없어요.')),
              for (final card in entry.$2.cards)
                ExpansionTile(
                    title: Text(card.title),
                    subtitle: Text(card.dateLabel),
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(card.fullText))
                    ]),
              if (entry.$2.draft != null)
                ExpansionTile(title: const Text('저장했던 임시 문장'), children: [
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(entry.$2.draft!))
                ]),
              ExpansionTile(
                  title: const Text('저장한 말씀'),
                  children: _verseWidgets(
                      (entry.$2.engagement['savedVerseIds'] is List
                          ? (entry.$2.engagement['savedVerseIds'] as List)
                              .whereType<String>()
                          : const <String>[]))),
              ExpansionTile(
                  title: const Text('최근 선택한 말씀'),
                  children: _verseWidgets(entry.$2.recentVerseIds)),
              if (entry.$2.engagement['journey'] is Map)
                ExpansionTile(title: const Text('7일 마음의 여정'), children: [
                  if ((entry.$2.engagement['journey'] as Map)['checkins']
                      is List)
                    for (final checkin in ((entry.$2.engagement['journey']
                            as Map)['checkins'] as List)
                        .whereType<Map>())
                      ListTile(
                          title: Text(
                              '${checkin['date'] ?? ''} · ${checkin['mood'] ?? ''}'),
                          subtitle: Text([checkin['note'], checkin['action']]
                              .whereType<String>()
                              .join('\n'))),
                ]),
              ExpansionTile(title: const Text('마음 선택 기록'), children: [
                for (final count in entry.$2.presetCounts.entries)
                  ListTile(
                      title: Text(EmotionType.fromWire(count.key).label),
                      trailing: Text('${count.value}회')),
                for (final count in entry.$2.customCounts.entries)
                  ListTile(
                      title: Text(count.key),
                      trailing: Text('${count.value}회')),
              ]),
              if (entry.$2.unreadableItems > 0)
                const ListTile(
                    title: Text('일부 기록을 읽지 못했어요. 해당 원본은 삭제하지 않고 보존합니다.')),
            ]),
      ]));
}
