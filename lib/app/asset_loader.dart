import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../onaria.dart';
import 'api_config.dart';

class FlutterVerseAssetLoader implements VerseAssetLoader {
  const FlutterVerseAssetLoader();

  @override
  Future<String> loadString(String path) => rootBundle.loadString(path);
}

class ServerFirstVerseAssetLoader implements VerseAssetLoader {
  const ServerFirstVerseAssetLoader({
    this.fallback = const FlutterVerseAssetLoader(),
    this.timeout = const Duration(seconds: 3),
  });

  final VerseAssetLoader fallback;
  final Duration timeout;

  @override
  Future<String> loadString(String path) async {
    final base = ApiConfig.baseUrl;
    if (base != null && path == 'assets/data/bible_verses_ko.json') {
      final uri = base.resolve('/v1/content/bible');
      try {
        final response = await http.get(uri).timeout(timeout);
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          return response.body;
        }
      } catch (_) {
        // Offline/server failure keeps the tested bundled Korean fallback usable.
      }
    }
    return fallback.loadString(path);
  }
}
