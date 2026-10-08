import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/src/bible/full_bible_repository.dart';

void main() {
  for (final language in ['ko', 'en']) {
    final bible = FullBible(jsonDecode(
            File('assets/data/full_bible_$language.json').readAsStringSync())
        as Map<String, dynamic>);
    test('$language complete corpus and unique references', () {
      expect(bible.books.length, 66);
      expect(bible.verses.length, language == 'ko' ? 31084 : 31103);
      expect(
          bible.verses
              .map((v) => '${v.book}:${v.chapter}:${v.number}')
              .toSet()
              .length,
          bible.verses.length);
      expect(bible.verses.map((v) => '${v.book}:${v.chapter}').toSet().length,
          1189);
      expect(bible.verses.last.book, 65);
      expect(bible.search(''), isEmpty);
      expect(bible.search('no-such-verse-987654321'), isEmpty);
    });
    test('$language reference search and chapter reading', () {
      final results =
          bible.search(language == 'ko' ? '요한복음 3:16' : 'John 3:16');
      expect(results.length, 1);
      expect(results.single.book, 42);
      expect(results.single.text, contains(language == 'ko' ? '하나님' : 'God'));
      expect(bible.chapter(results.single).length, 36);
      expect(
          bible.search(language == 'ko' ? '사랑' : 'LOVE', limit: 7).length, 7);
    });
  }
}
