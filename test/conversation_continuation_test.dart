import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/onaria.dart';
import 'package:onaria/app/app_theme.dart';
import 'package:onaria/app/ai_consent.dart';
import 'package:onaria/features/conversation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _ContinueClient implements LlmApiClient {
  _ContinueClient(this.fail);
  final bool fail;
  int calls = 0;
  @override
  Future<LlmConversationResponse> send(LlmConversationRequest request) async {
    calls++;
    if (fail) throw StateError('offline fixture');
    return const LlmConversationResponse(message: '마음을 돌아볼게요.',
      question: '어떤 마음이 드나요?', stage: ConversationStage.need,
      detectedEmotion: EmotionType.disgust, riskLevel: 0,
      shouldOfferVerse: false, shouldEndConversation: false,
      continueConversation: true);
  }
}
void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await SharedPreferencesAsync().setString(AiConsent.preferenceKey, AiConsent.version);
    for (final channel in ['flutter_tts', 'plugin.csdcorp.com/speech_to_text']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(channel), (_) async => 1);
    }
  });
  tearDown(() { SharedPreferencesAsyncPlatform.instance = null; });
  for (final fail in [false, true]) {
    testWidgets('five high-intensity turns continue to verse choice and action offline=$fail', (tester) async {
      rootBundle.clear();
      await tester.runAsync(() => Future.wait([rootBundle.loadString('assets/data/bible_verses_ko.json'), rootBundle.loadString('assets/data/content_release_baseline.json')]));
      final client = _ContinueClient(fail);
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
        home: ConversationPage(animateComposerBorder: false, emotion: EmotionType.disgust, intensity: 10, apiClient: client)));
      await tester.pumpAndSettle();
      for (var turn = 1; turn <= 5; turn++) {
        await tester.enterText(find.byType(TextField), '오늘 있었던 일을 차분히 돌아보고 싶어요.');
        await tester.tap(find.byTooltip('보내기'));
        for (var i = 0; i < 80 && client.calls < turn; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(client.calls, turn);
      }
      expect(find.byType(TextField), findsNothing);
      if (find.text('작은 실천 정하기').evaluate().isNotEmpty) {
        await tester.ensureVisible(find.text('작은 실천 정하기'));
        await tester.tap(find.text('작은 실천 정하기'));
      } else {
        expect(find.text('지금은 괜찮아요'), findsOneWidget);
        await tester.tap(find.text('지금은 괜찮아요'));
      }
      await tester.pumpAndSettle();
      expect(find.text('작은 실천'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
