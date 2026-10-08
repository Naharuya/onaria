import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/features/bible_search_page.dart';
import 'package:onaria/src/bible/full_bible_repository.dart';
import 'package:onaria/src/verses/verse_repository.dart';

class _Loader implements VerseAssetLoader {
  @override
  Future<String> loadString(String path) async => throw StateError('fixture');
}

class _Repository extends FullBibleRepository {
  _Repository() : super(_Loader());
  @override
  Future<FullBible> load(String language) async => FullBible({
        'edition': 'fixture',
        'books': ['창세기'],
        'verses': [
          [0, 1, 1, '태초에 하나님이'],
          [0, 1, 2, '땅이 혼돈하고']
        ],
      });
}

void main() {
  testWidgets('search opens complete chapter, including unsearched verses',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: BibleSearchPage(repository: _Repository())));
    await tester.enterText(find.byType(TextField), '하나님');
    await tester.tap(find.byTooltip('검색'));
    await tester.pumpAndSettle();
    expect(find.text('창세기 1:1'), findsOneWidget);
    expect(find.text('땅이 혼돈하고'), findsNothing);
    await tester.tap(find.text('창세기 1:1'));
    await tester.pumpAndSettle();
    expect(find.text('2. 땅이 혼돈하고'), findsOneWidget);
  });
}
