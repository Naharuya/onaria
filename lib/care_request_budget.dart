import 'dart:convert';

/// Stay below the existing 16 KiB server limit. Local session text is untouched.
Map<String, dynamic> boundedCareRequest(Map<String, dynamic> source) {
  final session = Map<String, dynamic>.from(source['session'] as Map);
  final supplied = session['personalizationContext'];
  if (supplied is! Map) return source;
  final body = Map<String, dynamic>.from(source);
  final original = Map<String, dynamic>.from(supplied);
  final context = Map<String, dynamic>.from(original);
  body['session'] = session;
  session['personalizationContext'] = context;
  context['historyCompacted'] = true;
  String shorten(Object? value, int limit) {
    final text = value is String ? value : '';
    final chars = text.runes.toList();
    if (chars.length <= limit) return text;
    final half = (limit - 3) ~/ 2;
    return String.fromCharCodes(chars.take(half)) +
        ' … ' +
        String.fromCharCodes(chars.skip(chars.length - half));
  }

  var limit = 256;
  void compact() {
    context['situation'] = shorten(original['situation'], limit);
    final answers = List<String>.from(original['alreadyAnswered'] as List);
    context['alreadyAnswered'] = [
      for (var i = 0; i < answers.length; i++)
        i == answers.length - 1 ? '' : shorten(answers[i], limit),
    ];
    // The server restores the last answer from userMessage. Never send it twice.
    context['askedQuestions'] = [
      for (final q in original['askedQuestions'] as List)
        shorten(q, limit.clamp(32, 120)),
    ];
    for (final key in [
      'conversationSummary',
      'conversationMemory',
      'previousUserAnswer',
      'previousAssistantQuestion'
    ]) {
      if (session[key] is String) {
        session[key] = shorten((source['session'] as Map)[key], limit);
      }
    }
  }

  compact();
  while (utf8.encode(jsonEncode(body)).length > 15000 && limit > 16) {
    limit ~/= 2;
    compact();
  }
  final ids = List<String>.from(body['allowedVerseIds'] as List? ?? const []);
  body['allowedVerseIds'] = ids;
  while (utf8.encode(jsonEncode(body)).length > 15000 && ids.length > 1) {
    ids.removeLast();
    if (body['verseCandidates'] is List) {
      body['verseCandidates'] = (body['verseCandidates'] as List)
          .where((v) => ids.contains((v as Map)['id']))
          .toList();
    }
  }
  if (body['verseCandidates'] is List) {
    final candidates = List<dynamic>.from(body['verseCandidates'] as List);
    body['verseCandidates'] = candidates;
    while (
        utf8.encode(jsonEncode(body)).length > 15000 && candidates.isNotEmpty) {
      candidates.removeLast();
    }
  }
  return body;
}
