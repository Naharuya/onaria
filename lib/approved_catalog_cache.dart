import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'content_release.dart';

class ApprovedCatalogCache {
  ApprovedCatalogCache(
      {required this.project,
      required Map<String, dynamic> bundled,
      required Map<String, dynamic> baseline,
      required this.endpoint,
      this.validate,
      this.readPublic,
      this.writePublic,
      DateTime Function()? clock,
      http.Client? client})
      : _snapshot = bundled,
        policy = ContentReleasePolicy(
            project: project, baseline: baseline, clock: clock),
        _clock = clock ?? DateTime.now,
        _client = client;
  final String project;
  final Future<String?> Function(String)? readPublic;
  final Future<void> Function(String, String)? writePublic;
  final Uri? endpoint;
  final Map<String, dynamic> Function(dynamic)? validate;
  final DateTime Function() _clock;
  final http.Client? _client;
  final ContentReleasePolicy policy;
  Map<String, dynamic> _snapshot;
  String? _etag;
  DateTime? _attempt;
  Future<void>? _restoring, _refreshing;
  bool _closed = false;
  String get _key => '$project.public.approved_catalog.v1';
  Map<String, dynamic> get current => policy.filter(_snapshot);
  Future<void> restore() => _restoring ??= _restore();
  Future<void> _restore() async {
    try {
      final raw = await (readPublic?.call(_key) ??
              SharedPreferencesAsync().getString(_key))
          .timeout(const Duration(seconds: 2));
      if (raw == null) return;
      if (raw.length > 2200000)
        throw const FormatException('Invalid public receipt cache');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['observedAt'] is int)
        policy.restoreObservedTime(data['observedAt'] as int);
      final catalog = Map<String, dynamic>.from(data['catalog'] as Map);
      final checked = validate?.call(catalog) ?? catalog;
      if (!policy.accept(checked['_release']))
        throw const FormatException('Invalid public receipt');
      _snapshot = checked;
    } catch (_) {
      // If prior revocation state cannot be read, do not revive the bundled allowance.
      policy.accept({
        'schemaVersion': 1,
        'project': project,
        'entries': [],
        'blockedIds': []
      });
    }
  }

  Future<void> refresh({bool force = false}) {
    if (_closed || endpoint == null) return Future.value();
    if (_refreshing != null) return _refreshing!;
    final now = _clock();
    if (!force &&
        _attempt != null &&
        now.difference(_attempt!) < const Duration(minutes: 5))
      return Future.value();
    _attempt = now;
    return _refreshing = _fetch().whenComplete(() => _refreshing = null);
  }

  Future<void> _fetch() async {
    final uri = endpoint!;
    if (uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) return;
    final client = _client ?? http.Client();
    try {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers.addAll({
          'Accept': 'application/json',
          if (_etag != null) 'If-None-Match': _etag!
        });
      final response =
          await client.send(request).timeout(const Duration(seconds: 5));
      if (_closed || response.statusCode == 304)
        return; // Never renew a lease from a 304.
      if (response.statusCode != 200) return;
      final bytes = BytesBuilder();
      await for (final chunk
          in response.stream.timeout(const Duration(seconds: 5))) {
        if (bytes.length + chunk.length > 2000000)
          throw const FormatException('Public catalog too large');
        bytes.add(chunk);
      }
      final value = jsonDecode(utf8.decode(bytes.takeBytes()));
      final next =
          validate?.call(value) ?? Map<String, dynamic>.from(value as Map);
      if (_closed || !policy.accept(next['_release'])) return;
      _snapshot = policy.filter(next);
      _etag = response.headers['etag'];
      try {
        final raw = jsonEncode(
            {'catalog': _snapshot, 'observedAt': policy.observedTime});
        if (writePublic != null) {
          await writePublic!(_key, raw);
        } else {
          await SharedPreferencesAsync().setString(_key, raw);
        }
      } catch (_) {/* No user data in this optional public cache. */}
    } catch (_) {
      /* Keep only unexpired hash-matched leases. No stale unapproved fallback. */
    } finally {
      if (_client == null) client.close();
    }
  }

  void close() {
    _closed = true;
    _client?.close();
  }
}
