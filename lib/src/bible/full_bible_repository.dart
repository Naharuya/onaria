import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../verses/verse_repository.dart';

Map<String, dynamic> _decodeBible(String text) =>
    jsonDecode(text) as Map<String, dynamic>;

class FullBibleVerse {
  const FullBibleVerse(this.book, this.chapter, this.number, this.text);
  final int book;
  final int chapter;
  final int number;
  final String text;
}

class FullBible {
  FullBible(Map<String, dynamic> json)
      : edition = json['edition'] as String,
        books = List<String>.from(json['books'] as List),
        verses = (json['verses'] as List)
            .map((dynamic row) => FullBibleVerse(
                row[0] as int, row[1] as int, row[2] as int, row[3] as String))
            .toList();
  final String edition;
  final List<String> books;
  final List<FullBibleVerse> verses;
  String reference(FullBibleVerse v) =>
      '${books[v.book]} ${v.chapter}:${v.number}';
  List<FullBibleVerse> search(String query, {int limit = 100}) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return [];
    final ref = RegExp(r'^(.+?)\s*(\d+)(?::(\d+))?$').firstMatch(needle);
    if (ref != null) {
      final book = books.indexWhere((b) =>
          b.toLowerCase().replaceAll(' ', '') == ref[1]!.replaceAll(' ', ''));
      if (book >= 0) {
        return verses
            .where((v) =>
                v.book == book &&
                v.chapter == int.parse(ref[2]!) &&
                (ref[3] == null || v.number == int.parse(ref[3]!)))
            .take(limit)
            .toList();
      }
    }
    return verses
        .where((v) => v.text.toLowerCase().contains(needle))
        .take(limit)
        .toList();
  }

  List<FullBibleVerse> chapter(FullBibleVerse verse) => verses
      .where((v) => v.book == verse.book && v.chapter == verse.chapter)
      .toList();
}

class FullBibleRepository {
  FullBibleRepository(this.loader);
  final VerseAssetLoader loader;
  final Map<String, Future<FullBible>> _cache = {};
  Future<FullBible> load(String language) {
    if (language != 'ko' && language != 'en') {
      throw ArgumentError.value(language);
    }
    return _cache.putIfAbsent(language, () async {
      try {
        return FullBible(await compute(_decodeBible,
            await loader.loadString('assets/data/full_bible_$language.json')));
      } catch (_) {
        _cache.remove(language);
        rethrow;
      }
    });
  }
}
