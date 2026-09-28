import 'dart:async';
import 'package:flutter/services.dart';
import 'session.dart';

abstract class DeviceFeatures {
  Future<bool> invoke(String method, [Map<String, Object?>? arguments]);
}

class AndroidDeviceFeatures implements DeviceFeatures {
  static const channel = MethodChannel('com.onaria.buddhist/offline');
  @override
  Future<bool> invoke(String method, [Map<String, Object?>? arguments]) async =>
      await channel.invokeMethod<bool>(method, arguments) ?? false;
}

class BuddhistEngagement {
  BuddhistEngagement(this.session, {DeviceFeatures? device})
      : device = device ?? AndroidDeviceFeatures() {
    session.addSafetyListener(_safetyStop);
  }
  final BuddhistSession session;
  final DeviceFeatures device;
  bool _busy = false;
  bool _disposed = false;
  int _generation = 0;
  String preview(String id) {
    if (_disposed || session.isCrisis) throw StateError('SAFETY_FIRST');
    final detail = session.savedDetail(id);
    if (detail == null) throw StateError('UNSUPPORTED_SCRIPTURE');
    session.provider.assertCitation(detail.scripture.metadata);
    final source = detail.scripture;
    return 'TEST_DATA_ONLY · 실제 경전이 아닌 합성 테스트 자료\n'
        '${source.title}\n${source.text}\n출처: ${source.source}\n이용 조건: ${source.license}';
  }

  Future<bool> share(String id) => _run('share', {'text': preview(id)});
  Future<bool> speak(String id) => _run('speak', {'text': preview(id)});
  Future<bool> reminder(int minutes) {
    if (minutes != 1 && minutes != 1440) throw ArgumentError('INVALID_DELAY');
    return _run('reminder', {'minutes': minutes});
  }

  Future<bool> _run(String method, Map<String, Object?> arguments) async {
    if (_disposed || session.isCrisis) throw StateError('SAFETY_FIRST');
    if (_busy) throw StateError('BUSY');
    final generation = _generation;
    final scope = session.recordScope;
    _busy = true;
    try {
      final ok = await device.invoke(method, arguments);
      if (_disposed ||
          session.isCrisis ||
          generation != _generation ||
          !identical(scope, session.recordScope)) {
        await _quiet('safetyStop');
        return false;
      }
      return ok;
    } finally {
      _busy = false;
    }
  }

  Future<bool> stopSpeech() => _quiet('stopSpeech');
  Future<bool> cancelReminder() => _quiet('cancelReminder');
  Future<bool> _quiet(String method) async {
    try {
      return await device.invoke(method);
    } catch (_) {
      return false;
    }
  }

  void _safetyStop() {
    _generation++;
    unawaited(_quiet('safetyStop'));
  }

  void dispose() {
    _disposed = true;
    _generation++;
    session.removeSafetyListener(_safetyStop);
    unawaited(stopSpeech());
  }
}

class GrowthSnapshot {
  GrowthSnapshot(BuddhistSession session, DateTime now) {
    if (session.isCrisis) return;
    for (var offset = 6; offset >= 0; offset--) {
      final day = DateTime(now.year, now.month, now.day - offset);
      final end = DateTime(day.year, day.month, day.day + 1);
      days[day] = session.savedDetails
          .where((row) =>
              row.savedAt != null &&
              !row.savedAt!.toLocal().isBefore(day) &&
              row.savedAt!.toLocal().isBefore(end))
          .length;
    }
  }
  final Map<DateTime, int> days = {};
  int get total => days.values.fold(0, (a, b) => a + b);
}
