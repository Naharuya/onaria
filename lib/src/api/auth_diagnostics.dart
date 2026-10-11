import 'dart:io';

import 'package:flutter/foundation.dart';

/// Opt-in device verification. Never accepts credentials, bodies or headers.
class AuthDiagnostics {
  static const enabled = bool.fromEnvironment('ONARIA_AUTH_DIAGNOSTICS');
  static Future<void> _writes = Future<void>.value();
  static const _operations = {
    'POST /v1/auth/provider/session': 'login',
    'DELETE /v1/auth/provider/session': 'logout',
    'POST /v1/auth/provider/signup': 'signup_or_link',
    'GET /v1/account': 'account',
  };

  static void record(String method, String path, int status) {
    if (!enabled || status < 100 || status > 599) return;
    final operation = _operations['$method $path'];
    if (operation == null) return;
    final event = 'ONARIA_AUTH_STATUS operation=$operation status=$status';
    _emit(event);
  }

  static void failure(String method, String path, String reason) {
    if (!enabled ||
        !const {'timeout', 'network', 'tls', 'transport'}.contains(reason)) {
      return;
    }
    final operation = _operations['$method $path'];
    if (operation == null) return;
    _emit('ONARIA_AUTH_STATUS operation=$operation failure=$reason');
  }

  static void _emit(String event) {
    debugPrint(event);
    if (Platform.isIOS) {
      _writes = _writes
          .then((_) => persistTo(
              File('${Directory.systemTemp.path}/onaria-auth-status.log'),
              event))
          .catchError((_) {});
    }
  }

  /// Only fixed diagnostics, never request/response content. Temporary and
  /// bounded so opt-in device review cannot become a permanent activity log.
  @visibleForTesting
  static Future<void> persistTo(File file, String event) async {
    final valid = RegExp(
        r'^ONARIA_AUTH_STATUS operation=(login|logout|signup_or_link|account) (status=[1-5][0-9]{2}|failure=(timeout|network|tls|transport))$');
    if (!valid.hasMatch(event)) return;
    final lines = await file.exists() ? await file.readAsLines() : <String>[];
    final safe = lines.where(valid.hasMatch).toList()..add(event);
    await file.writeAsString(
        '${safe.skip(safe.length > 64 ? safe.length - 64 : 0).join('\n')}\n',
        flush: true);
  }
}
