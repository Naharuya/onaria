import 'dart:convert';
import 'dart:io';
import 'local_conversation_client.dart';

abstract class AsyncConversationClient {
  Future<Map<String, Object?>> respond(LocalConversationRequest request);
  void cancel();
}

/// Explicit USB development build only; never accepts a remote host.
class MacAiClient implements AsyncConversationClient {
  static const port = int.fromEnvironment('BUDDHIST_MAC_AI_PORT');
  static const token = String.fromEnvironment('BUDDHIST_MAC_AI_TOKEN');
  static bool get enabled => port > 1023 && port <= 65535 && token.length == 64;
  HttpClient? _http;
  @override
  Future<Map<String, Object?>> respond(LocalConversationRequest input) async {
    if (!enabled) throw StateError('MAC_AI_NOT_CONFIGURED');
    final http =
        _http = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      return await (() async {
        final req = await http.postUrl(
            Uri(scheme: 'http', host: '127.0.0.1', port: port, path: '/reply'));
        req.followRedirects = false;
        req.headers.contentType = ContentType.json;
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        req.write(jsonEncode({
          'profile': 'buddhist',
          'phase': input.phase.name,
          'emotion': input.emotion.name,
          'intensity': input.intensity,
          'input': input.input,
          'previousInputs': input.previousInputs
        }));
        final response = await req.close();
        if (response.statusCode != 200) throw StateError('MAC_AI_UNAVAILABLE');
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 2048) throw StateError('INVALID_REPLY');
        }
        final result = jsonDecode(utf8.decode(bytes));
        if (result is! Map<String, dynamic>) throw StateError('INVALID_REPLY');
        return result;
      })()
          .timeout(const Duration(seconds: 22));
    } finally {
      http.close(force: true);
      if (identical(_http, http)) _http = null;
    }
  }

  @override
  void cancel() {
    _http?.close(force: true);
    _http = null;
  }
}
