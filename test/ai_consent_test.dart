import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/ai_consent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty());
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);
  test('versioned consent starts absent and withdrawal removes permission',
      () async {
    expect(await AiConsent.isGranted(), isFalse);
    await SharedPreferencesAsync()
        .setString(AiConsent.preferenceKey, 'obsolete');
    expect(await AiConsent.isGranted(), isFalse);
    await AiConsent.grant();
    expect(await AiConsent.isGranted(), isTrue);
    await AiConsent.withdraw();
    expect(await AiConsent.isGranted(), isFalse);
  });
  testWidgets('cancel does not grant; affirmative permission is persisted',
      (tester) async {
    bool? decision;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () async =>
                    decision = await AiConsent.request(context),
                child: const Text('send')))));
    await tester.tap(find.text('send'));
    await tester.pumpAndSettle();
    expect(find.textContaining('OpenAI'), findsOneWidget);
    await tester.tap(find.text('전송하지 않기'));
    await tester.pumpAndSettle();
    expect(decision, isFalse);
    expect(await AiConsent.isGranted(), isFalse);
    await tester.tap(find.text('send'));
    await tester.pumpAndSettle();
    // An unchecked age affirmation must never authorize transmission.
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '허용하고 보내기'))
            .onPressed,
        isNull);
    await tester.tap(find.text('허용하고 보내기'));
    await tester.pumpAndSettle();
    expect(await AiConsent.isGranted(), isFalse);
    expect(decision, isFalse);
    await tester.tap(find.text('만 18세 이상입니다.'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '허용하고 보내기'))
            .onPressed,
        isNotNull);
    await tester.tap(find.text('허용하고 보내기'));
    await tester.pumpAndSettle();
    expect(decision, isTrue);
    expect(await AiConsent.isGranted(), isTrue);
  });
}
