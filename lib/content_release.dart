import 'dart:convert';
import 'package:crypto/crypto.dart';

String canonicalContent(dynamic value) {
  if (value == null || value is String || value is bool)
    return jsonEncode(value);
  if (value is int && value.abs() <= 9007199254740991) return jsonEncode(value);
  if (value is List) return '[${value.map(canonicalContent).join(',')}]';
  if (value is Map && value.keys.every((key) => key is String)) {
    final keys = value.keys.cast<String>().toList()..sort();
    return '{${keys.map((key) => '${jsonEncode(key)}:${canonicalContent(value[key])}').join(',')}}';
  }
  throw const FormatException('Unsupported approval payload');
}

Map<String, dynamic> contentPayload(
    String project, Map<String, dynamic> catalog, Map<String, dynamic> item) {
  Map<String, dynamic> pick(List<String> keys) => {
        for (final key in keys)
          if (catalog.containsKey(key)) key: catalog[key]
      };
  if (project == 'onaria')
    return {
      'item': item,
      'catalog': pick(
          ['translation', 'copyrightNotice', 'englishLicense', 'koreanLicense'])
    };
  if (project == 'catholic')
    return {
      'item': item,
      'catalog': pick(['title', 'sourceEdition', 'rightsUrl', 'notice'])
    };
  if (project == 'sorua') {
    final quotes = catalog['sourceQuotations'] as List? ?? const [];
    return {
      'item': item,
      'sourceQuotation': quotes
          .whereType<Map>()
          .where((q) => q['id'] == item['sourceQuoteId'])
          .firstOrNull,
      'catalog': pick(['translation', 'copyrightNotice', 'quotationReviewDate'])
    };
  }
  return {'item': item};
}

String approvedContentHash(
        {required String project,
        required String reference,
        required String kind,
        required Map<String, dynamic> payload}) =>
    sha256
        .convert(utf8.encode(canonicalContent({
          'project': project,
          'reference': reference,
          'kind': kind,
          'payload': payload
        })))
        .toString();

/// Public distribution leases only. Neither this class nor its cache accepts user records.
class ContentReleasePolicy {
  ContentReleasePolicy(
      {required this.project,
      required Map<String, dynamic> baseline,
      DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    accept(baseline);
  }
  final String project;
  final DateTime Function() _clock;
  final Map<String, Map<String, dynamic>> _proofs = {};
  int _lastSeen = 0;
  static const maxOffline = {
    'source_quote': 604800,
    'ai_translation_draft': 604800,
    'original_creative': 2592000
  };
  int get observedTime {
    final wall = _clock().millisecondsSinceEpoch;
    if (wall > _lastSeen) _lastSeen = wall;
    return _lastSeen;
  }

  void restoreObservedTime(int value) {
    if (value > _lastSeen) _lastSeen = value;
  }

  bool accept(dynamic envelope) {
    if (envelope is! Map ||
        envelope['schemaVersion'] != 1 ||
        envelope['project'] != project ||
        envelope['entries'] is! List ||
        (envelope['entries'] as List).length > 10000 ||
        envelope['blockedIds'] is! List) return false;
    final now = observedTime,
        next = <String, Map<String, dynamic>>{},
        blocked = (envelope['blockedIds'] as List);
    if (blocked.length > 10000 || blocked.any((id) => id is! String))
      return false;
    for (final raw in envelope['entries'] as List) {
      if (raw is! Map) return false;
      final p = Map<String, dynamic>.from(raw),
          id = p['reference'],
          kind = p['kind'],
          issued = p['issuedAt'],
          expires = p['expiresAt'],
          seconds = p['offlineSeconds'];
      if (id is! String ||
          !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$').hasMatch(id) ||
          next.containsKey(id) ||
          blocked.contains(id) ||
          !maxOffline.containsKey(kind) ||
          p['contentHash'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(p['contentHash'] as String) ||
          !const ['published', 'existing_distribution'].contains(p['state']) ||
          issued is! int ||
          expires is! int ||
          seconds is! int ||
          seconds < 0 ||
          seconds > maxOffline[kind]! ||
          issued > now + 300000 ||
          expires <= issued ||
          expires - issued > (seconds == 0 ? 300 : seconds) * 1000)
        return false;
      next[id] = p;
    }
    // A complete server envelope replaces the prior allowance, including bundled fallback.
    _proofs
      ..clear()
      ..addAll(next);
    return true;
  }

  bool allows(Map<String, dynamic> item, Map<String, dynamic> catalog,
      {bool online = false}) {
    final id = item['id'];
    if (id is! String) return false;
    final p = _proofs[id];
    if (p == null ||
        observedTime >= p['expiresAt'] ||
        (p['offlineSeconds'] == 0 && !online)) return false;
    final kind = project == 'catholic'
        ? 'ai_translation_draft'
        : project == 'sorua'
            ? (item['sourceQuoteId'] == null
                ? 'original_creative'
                : 'source_quote')
            : project == 'buddhist'
                ? (item['kind'] == 'original_creative'
                    ? 'original_creative'
                    : 'source_quote')
                : 'source_quote';
    if (kind != p['kind']) return false;
    try {
      return p['contentHash'] ==
          approvedContentHash(
              project: project,
              reference: id,
              kind: kind,
              payload: contentPayload(project, catalog, item));
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> filter(Map<String, dynamic> catalog,
      {bool online = false}) {
    final key = project == 'onaria' || project == 'sorua' ? 'verses' : 'items';
    final rows = catalog[key];
    if (rows is! List) throw const FormatException('Invalid catalog');
    final approved = [
      for (final row in rows)
        if (row is Map<String, dynamic> && allows(row, catalog, online: online))
          row
    ];
    final sources = approved.map((item) => item['sourceQuoteId']).toSet();
    return {
      ...catalog,
      key: approved,
      if (project == 'sorua')
        'sourceQuotations': [
          for (final source in catalog['sourceQuotations'] as List? ?? const [])
            if (source is Map && sources.contains(source['id'])) source
        ]
    };
  }
}
