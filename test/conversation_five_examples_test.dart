import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/app_theme.dart';
import 'package:onaria/features/conversation_page.dart';
import 'package:onaria/common_emotion_examples.dart';
import 'package:onaria/onaria.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });
  tearDown(() { SharedPreferencesAsyncPlatform.instance = null; });
  for (final entry in [(EmotionType.sadness, 8), (EmotionType.anxiety, 10), (EmotionType.complexity, 5)]) {
    testWidgets('five starting examples survive emotion and intensity ${entry.$1} ${entry.$2}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final channel in ['flutter_tts', 'plugin.csdcorp.com/speech_to_text']) {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channel), (_) async => 1);
      }
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
        home: ConversationPage(animateComposerBorder: false, emotion: entry.$1, intensity: entry.$2)));
      await tester.pumpAndSettle();
      final candidates = commonCardExamples(entry.$1.label, intensity: entry.$2);
      for (final example in candidates.take(5)) {
        expect(find.widgetWithText(OutlinedButton, example), findsOneWidget);
      }
      expect(find.byType(OutlinedButton), findsNWidgets(5));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
