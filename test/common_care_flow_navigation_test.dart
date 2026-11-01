import 'package:onaria/engagement/mini_games/cross_light/cross_light_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:onaria/onaria.dart';
import 'package:onaria/app/ai_consent.dart';
import 'package:onaria/app/app_theme.dart';
import 'package:onaria/features/conversation_page.dart';
import 'package:onaria/features/growth_page.dart';

class EndingClient implements LlmApiClient {
  int calls = 0;
  @override
  Future<LlmConversationResponse> send(LlmConversationRequest request) async {
    calls++;
    return const LlmConversationResponse(
        message: '오늘 마음을 돌아봤어요.',
        stage: ConversationStage.ended,
        detectedEmotion: EmotionType.gratitude,
        riskLevel: 0,
        shouldOfferVerse: false,
        shouldEndConversation: true);
  }
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesAsync()
        .setString(AiConsent.preferenceKey, AiConsent.version);
    for (final channel in [
      'flutter_tts',
      'plugin.csdcorp.com/speech_to_text'
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (_) async => 1);
    }
  });
  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });
  testWidgets(
      'safe ended dialogue can reach content, practice, save and records without a game',
      (t) async {
    t.view.physicalSize = const Size(800, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final textScale = ValueNotifier<double>(1);
    addTearDown(textScale.dispose);
    rootBundle.clear();
    await t.runAsync(() => Future.wait([rootBundle.loadString('assets/data/bible_verses_ko.json'), rootBundle.loadString('assets/data/content_release_baseline.json')]));
    final client = EndingClient();
    await t.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => ValueListenableBuilder<double>(
              valueListenable: textScale,
              builder: (context, scale, _) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
            ),
        home: ConversationPage(
            animateComposerBorder: false,
            emotion: EmotionType.gratitude,
            intensity: 5,
            apiClient: client)));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '고마운 하루를 돌아보고 싶어요.');
    await t.tap(find.byTooltip('보내기'));
    for (var i = 0; i < 80 && client.calls == 0; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    await t.pumpAndSettle();
    final content = find.text('말씀 선택으로 이어가기');
    await t.ensureVisible(content);
    await t.tap(content);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('care-step-content')), findsOneWidget);
    await t.ensureVisible(find.text('지금은 괜찮아요'));
    await t.tap(find.text('지금은 괜찮아요'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('care-step-practice')), findsOneWidget);
    final action = find.byType(OutlinedButton).first;
    await t.ensureVisible(action);
    await t.tap(action);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('care-card-actions')), findsOneWidget);
    t.view.physicalSize = const Size(320, 720);
    textScale.value = 2;
    await t.pumpAndSettle();
    final actions = find.byKey(const ValueKey('care-card-actions'));
    final buttons = find.descendant(
        of: actions,
        matching:
            find.byWidgetPredicate((widget) => widget is ButtonStyleButton));
    Rect? previous;
    for (final element in buttons.evaluate()) {
      final rect = t.getRect(find.byWidget(element.widget));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
      if (previous != null)
        expect(rect.top - previous.bottom, greaterThanOrEqualTo(12));
      previous = rect;
    }
    final game = find.byKey(const ValueKey('care-optional-game'));
    await t.ensureVisible(game);
    await t.pumpAndSettle();
    await t.tap(game);
    await t.pumpAndSettle();
    expect(find.byType(CrossLightPage), findsOneWidget);
    Navigator.of(t.element(find.byType(CrossLightPage))).pop();
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('care-card-actions')), findsOneWidget);
    t.view.physicalSize = const Size(800, 1200);
    textScale.value = 1;
    await t.pumpAndSettle();
    final save = find.byKey(const ValueKey('care-save-records'));
    await t.ensureVisible(save);
    await t.tap(save);
    for (var i = 0; i < 20; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    await t.pumpAndSettle();
    expect(find.byType(GrowthPage), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
