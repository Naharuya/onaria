import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../approved_catalog_cache.dart';
import '../onaria.dart';
import 'api_config.dart';

class FlutterVerseAssetLoader implements VerseAssetLoader {
  const FlutterVerseAssetLoader();
  static Future<ApprovedCatalogCache>? _cache;
  static Future<ApprovedCatalogCache> _open() async {
    final assets = await Future.wait([
      rootBundle.loadString('assets/data/bible_verses_ko.json'),
      rootBundle.loadString('assets/data/content_release_baseline.json')
    ]);
    final cache = ApprovedCatalogCache(
        project: 'onaria',
        bundled: jsonDecode(assets[0]) as Map<String, dynamic>,
        baseline: jsonDecode(assets[1]) as Map<String, dynamic>,
        endpoint: ApiConfig.baseUrl?.resolve('/v1/content/verses'));
    await cache.restore();
    return cache;
  }

  /// Prepares only bundled/public local receipts; never performs a network read.
  static Future<void> initializeLocal() async {
    await (_cache ??= _open().catchError((Object error) {
      _cache = null;
      throw error;
    }));
  }

  @override
  Future<String> loadString(String path) async {
    if (path != 'assets/data/bible_verses_ko.json')
      return rootBundle.loadString(path);
    final cache = await (_cache ??= _open().catchError((Object error) {
      _cache = null;
      throw error;
    }));
    unawaited(cache.refresh());
    return jsonEncode(cache.current);
  }
}
