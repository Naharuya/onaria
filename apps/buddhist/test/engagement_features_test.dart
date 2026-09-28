import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria_buddhist/engagement.dart';
import 'package:onaria_buddhist/session.dart';
import 'package:onaria_buddhist/mind_card_store.dart';
import 'package:onaria_buddhist_pack/onaria_buddhist_pack.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDevice implements DeviceFeatures {
  final List<String> methods = [];
  Map<String, Object?>? payload;
  Future<bool> Function(String)? handler;
  @override
  Future<bool> invoke(String method, [Map<String, Object?>? args]) async {
    methods.add(method);
    payload = args;
    return handler == null ? true : handler!(method);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BuddhistSession session;
  late FakeDevice device;
  late BuddhistEngagement effects;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    session = BuddhistSession(await BuddhistScriptureProvider.load(), prefs,
        cardStore:
            MindCardStore(prefs, clock: () => DateTime.utc(2026, 9, 28, 3)));
    session.respond('불안');
    session.makeCard(session.citations.first.id);
    await session.saveCard();
    device = FakeDevice();
    effects = BuddhistEngagement(session, device: device);
  });
  tearDown(() => effects.dispose());
  test(
      'Growth counts dated canonical cards only; preview carries exact source and mock label',
      () {
    final growth = GrowthSnapshot(session, DateTime(2026, 9, 28));
    expect(growth.days, hasLength(7));
    expect(growth.total, 1);
    final preview = effects.preview(session.card!.id);
    expect(preview, contains(session.card!.text));
    expect(preview, contains(session.card!.source));
    expect(preview, startsWith('TEST_DATA_ONLY'));
    expect(device.methods, isEmpty);
    expect(() => effects.preview('christian-id'), throwsStateError);
  });
  test(
      'Sharing and speech validate saved IDs; notification has no quotation payload',
      () async {
    final id = session.card!.id;
    await effects.share(id);
    expect(device.methods.last, 'share');
    expect(device.payload!.keys, ['text']);
    await effects.speak(id);
    expect(device.methods.last, 'speak');
    await effects.reminder(1);
    expect(device.payload, {'minutes': 1});
    expect(() => effects.reminder(0), throwsArgumentError);
    await effects.cancelReminder();
    expect(device.methods.last, 'cancelReminder');
  });
  test('Crisis stops queued device effects and blocks future calls', () async {
    final id = session.card!.id;
    final gate = Completer<bool>();
    device.handler =
        (method) => method == 'reminder' ? gate.future : Future.value(true);
    final pending = effects.reminder(1);
    session.respond('죽고 싶어요');
    expect(device.methods, contains('safetyStop'));
    gate.complete(true);
    expect(await pending, isFalse);
    expect(() => effects.preview(id), throwsStateError);
    await expectLater(effects.reminder(1), throwsStateError);
    expect(GrowthSnapshot(session, DateTime.now()).days, isEmpty);
  });
  test(
      'Platform rejection/exception never reports success and retry remains possible',
      () async {
    device.handler = (_) async => false;
    expect(await effects.reminder(1), isFalse);
    device.handler = (_) async => throw StateError('private error');
    await expectLater(effects.reminder(1), throwsStateError);
    device.handler = null;
    expect(await effects.reminder(1), isTrue);
  });
  test('A failing device listener cannot interrupt crisis cleanup', () {
    session.addSafetyListener(() => throw StateError('device failure'));
    session.respond('죽고 싶어요');
    expect(session.citations, isEmpty);
    expect(session.card, isNull);
    expect(GrowthSnapshot(session, DateTime.now()).days, isEmpty);
    expect(device.methods, contains('safetyStop'));
  });
}
