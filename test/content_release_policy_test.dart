import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/content_release.dart';
import 'package:onaria/approved_catalog_cache.dart';

Map<String, dynamic> sample(DateTime now, {int seconds = 604800}) {
  final catalog = <String, dynamic>{
    'translation': 'TEST_DATA_ONLY',
    'copyrightNotice': 'Synthetic fixture',
    'verses': [
      {'id': 'sample-1', 'text': 'Synthetic text only'}
    ]
  };
  final item = (catalog['verses'] as List).single as Map<String, dynamic>;
  catalog['_release'] = {
    'schemaVersion': 1,
    'project': 'onaria',
    'blockedIds': [],
    'entries': [
      {
        'reference': 'sample-1',
        'kind': 'source_quote',
        'state': 'published',
        'contentHash': approvedContentHash(
            project: 'onaria',
            reference: 'sample-1',
            kind: 'source_quote',
            payload: contentPayload('onaria', catalog, item)),
        'offlineSeconds': seconds,
        'issuedAt': now.millisecondsSinceEpoch,
        'expiresAt': now.millisecondsSinceEpoch + seconds * 1000
      }
    ]
  };
  return catalog;
}

void main() {
  test('real deployed baseline hashes match Dart exact rendered payloads', () {
    final baseline = jsonDecode(
        File('assets/data/content_release_baseline.json')
            .readAsStringSync()) as Map<String, dynamic>;
    final project = baseline['project'] as String;
    final path = {
      'onaria': 'assets/data/bible_verses_ko.json',
      'sorua': 'assets/data/philosophy_reflections_ko.json',
      'catholic': 'backend/content/daily-drafts.json',
      'buddhist': 'assets/data/buddhist_approved.json'
    }[project]!;
    final catalog =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final clock = DateTime.fromMillisecondsSinceEpoch(
        (baseline['generatedAt'] as int) + 1000);
    final policy = ContentReleasePolicy(
        project: project, baseline: baseline, clock: () => clock);
    final key = project == 'onaria' || project == 'sorua' ? 'verses' : 'items';
    if (project != 'buddhist')
      expect(policy.filter(catalog)[key],
          hasLength((baseline['entries'] as List).length));
    expect(
        (baseline['entries'] as List)
            .every((p) => p['state'] == 'existing_distribution'),
        isTrue);
  });
  test('edited body, project mismatch and expiry do not inherit approval', () {
    var now = DateTime.utc(2026, 11, 1);
    final catalog = sample(now);
    final policy = ContentReleasePolicy(
        project: 'onaria',
        baseline: catalog['_release'] as Map<String, dynamic>,
        clock: () => now);
    expect(policy.filter(catalog)['verses'], hasLength(1));
    final changed = jsonDecode(jsonEncode(catalog)) as Map<String, dynamic>;
    (changed['verses'] as List).single['text'] = 'Changed text';
    expect(policy.filter(changed)['verses'], isEmpty);
    expect(
        policy.accept({
          ...catalog['_release'] as Map<String, dynamic>,
          'project': 'sorua'
        }),
        isFalse);
    now = now.add(const Duration(days: 8));
    expect(policy.filter(catalog)['verses'], isEmpty);
    now = now.subtract(const Duration(days: 8));
    expect(policy.filter(catalog)['verses'], isEmpty);
  });
  test('a revocation envelope suppresses bundled fallback', () {
    final now = DateTime.utc(2026, 11, 1),
        catalog = sample(DateTime.utc(2026, 11, 1));
    final policy = ContentReleasePolicy(
        project: 'onaria',
        baseline: catalog['_release'] as Map<String, dynamic>,
        clock: () => now);
    expect(
        policy.accept({
          'schemaVersion': 1,
          'project': 'onaria',
          'entries': [],
          'blockedIds': ['sample-1']
        }),
        isTrue);
    expect(policy.filter(catalog)['verses'], isEmpty);
  });
  test('overlong leases and duplicate reference proofs are rejected', () {
    final now = DateTime.utc(2026, 11, 1),
        catalog = sample(DateTime.utc(2026, 11, 1));
    final envelope = catalog['_release'] as Map<String, dynamic>;
    final policy = ContentReleasePolicy(
        project: 'onaria', baseline: envelope, clock: () => now);
    final p = (envelope['entries'] as List).single as Map<String, dynamic>;
    expect(
        policy.accept({
          ...envelope,
          'entries': [p, p]
        }),
        isFalse);
    expect(
        policy.accept({
          ...envelope,
          'entries': [
            {...p, 'offlineSeconds': 604801}
          ]
        }),
        isFalse);
  });
  test('304 never extends approval expiry', () async {
    var now = DateTime.utc(2026, 11, 1);
    final catalog = sample(now, seconds: 1);
    var calls = 0;
    final client = MockClient((request) async => ++calls == 1
        ? http.Response(jsonEncode(catalog), 200, headers: {'etag': '"sample"'})
        : http.Response('', 304));
    final cache = ApprovedCatalogCache(
        project: 'onaria',
        bundled: catalog,
        baseline: catalog['_release'] as Map<String, dynamic>,
        endpoint: Uri.parse('https://api.onaria.ai.kr/v1/content/verses'),
        client: client,
        clock: () => now,
        readPublic: (_) async => null,
        writePublic: (_, __) async {});
    await cache.refresh(force: true);
    expect(cache.current['verses'], hasLength(1));
    now = now.add(const Duration(seconds: 2));
    await cache.refresh(force: true);
    expect(cache.current['verses'], isEmpty);
    cache.close();
  });
  test('known revocation survives a public-cache restart', () async {
    final now = DateTime.utc(2026, 11, 1),
        catalog = sample(DateTime.utc(2026, 11, 1));
    final disk = <String, String>{};
    final revoked = {
      ...catalog,
      'verses': [],
      '_release': {
        'schemaVersion': 1,
        'project': 'onaria',
        'entries': [],
        'blockedIds': ['sample-1']
      }
    };
    final cache = ApprovedCatalogCache(
        project: 'onaria',
        bundled: catalog,
        baseline: catalog['_release'] as Map<String, dynamic>,
        endpoint: Uri.parse('https://api.onaria.ai.kr/v1/content/verses'),
        client:
            MockClient((_) async => http.Response(jsonEncode(revoked), 200)),
        clock: () => now,
        readPublic: (key) async => disk[key],
        writePublic: (key, value) async {
          disk[key] = value;
        });
    await cache.refresh(force: true);
    expect(cache.current['verses'], isEmpty);
    cache.close();
    final reopened = ApprovedCatalogCache(
        project: 'onaria',
        bundled: catalog,
        baseline: catalog['_release'] as Map<String, dynamic>,
        endpoint: null,
        clock: () => now,
        readPublic: (key) async => disk[key]);
    await reopened.restore();
    expect(reopened.current['verses'], isEmpty);
    reopened.close();
  });

  test('unreadable, corrupt and foreign public receipts never revive the bundle', () async {
    final now = DateTime.utc(2026, 11, 1), catalog = sample(DateTime.utc(2026, 11, 1));
    for (final failure in ['unreadable', 'corrupt', 'foreign']) {
      final cache = ApprovedCatalogCache(
        project: 'onaria', bundled: catalog,
        baseline: catalog['_release'] as Map<String, dynamic>, endpoint: null, clock: () => now,
        readPublic: (_) async {
          if (failure == 'unreadable') throw StateError('TEST_STORAGE_UNAVAILABLE');
          if (failure == 'corrupt') return '{invalid';
          return jsonEncode({'catalog': {...catalog, '_release': {...catalog['_release'] as Map<String, dynamic>, 'project': 'sorua'}}});
        });
      await cache.restore();
      expect(cache.current['verses'], isEmpty, reason: failure);
      cache.close();
    }
  });
}
