import 'package:flutter/material.dart';
import '../app/asset_loader.dart';
import '../src/bible/full_bible_repository.dart';

class BibleSearchPage extends StatefulWidget {
  const BibleSearchPage({super.key, this.repository});
  final FullBibleRepository? repository;
  @override
  State<BibleSearchPage> createState() => _BibleSearchPageState();
}

class _BibleSearchPageState extends State<BibleSearchPage> {
  late final _repository =
      widget.repository ?? FullBibleRepository(const FlutterVerseAssetLoader());
  final _query = TextEditingController();
  String _language = 'ko';
  FullBible? _bible;
  List<FullBibleVerse> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;
  int _request = 0;
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final request = ++_request;
    final query = _query.text;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bible = await _repository.load(_language);
      final results = bible.search(query);
      if (!mounted || request != _request) return;
      setState(() {
        _bible = bible;
        _results = results;
        _searched = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = '성경을 불러오지 못했습니다. 다시 검색해 주세요.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('성경 검색')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ko', label: Text('개역한글')),
                      ButtonSegment(value: 'en', label: Text('WEB · 영어'))
                    ],
                    selected: {
                      _language
                    },
                    onSelectionChanged: (value) {
                      setState(() {
                        _language = value.single;
                        _results = [];
                        _searched = false;
                      });
                      _search();
                    }),
                const SizedBox(height: 12),
                TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                        labelText: '본문 또는 책·장·절',
                        hintText: _language == 'ko'
                            ? '사랑 / 요한복음 3:16'
                            : 'love / John 3:16',
                        suffixIcon: IconButton(
                            onPressed: _search,
                            tooltip: '검색',
                            icon: const Icon(Icons.search)))),
                const SizedBox(height: 8),
                Text(
                    _language == 'ko'
                        ? '개역한글 1952/1961 · Zefania 공개 배포본'
                        : 'World English Bible · eBible.org',
                    style: Theme.of(context).textTheme.bodySmall),
              ])),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
          if (!_searched && !_loading)
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('검색어를 입력해 주세요. 인터넷 없이 검색할 수 있습니다.')),
          if (_searched && _results.isEmpty && !_loading)
            const Padding(
                padding: EdgeInsets.all(16), child: Text('검색 결과가 없습니다.')),
          if (_results.length == 100)
            const Text('첫 100개 결과입니다. 검색어를 더 구체적으로 입력해 주세요.'),
          Expanded(
              child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final verse = _results[index];
                    final bible = _bible!;
                    return ListTile(
                        title: Text(bible.reference(verse)),
                        subtitle: Text(verse.text),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<
                                void>(
                            builder: (_) => Scaffold(
                                appBar: AppBar(
                                    title: Text(
                                        '${bible.books[verse.book]} ${verse.chapter}장')),
                                body: ListView(children: [
                                  Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(bible.edition)),
                                  ...bible.chapter(verse).map((v) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: SelectableText(
                                          '${v.number}. ${v.text}',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight:
                                                  v.number == verse.number
                                                      ? FontWeight.bold
                                                      : FontWeight.normal))))
                                ])))));
                  })),
        ]),
      );
}
