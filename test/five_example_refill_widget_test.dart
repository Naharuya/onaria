import 'package:onaria/personal_keywords.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onaria/app/ai_consent.dart';
import 'package:onaria/app/app_theme.dart';
import 'package:onaria/onaria.dart';
import 'package:onaria/features/conversation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Finder choices() => find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    ((w.key as ValueKey<String>).value.startsWith('conversation-example-')));

class ExampleClient implements LlmApiClient {
  int calls = 0;
  @override
  Future<LlmConversationResponse> send(LlmConversationRequest request) async {
    calls++;
    return LlmConversationResponse(
        message: '이야기를 들었어요.',
        question: '그때 어떤 생각이 들었나요?',
        stage: ConversationStage.thought,
        detectedEmotion: request.session.selectedEmotion,
        riskLevel: 0,
        shouldOfferVerse: false,
        shouldEndConversation: false);
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });
  testWidgets('visible five suggestions refill after selection', (t) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
    await SharedPreferencesAsync()
        .setString(AiConsent.preferenceKey, AiConsent.version);
    for (final channel in [
      'flutter_tts',
      'plugin.csdcorp.com/speech_to_text'
    ]) {
      t.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (_) async => 1);
    }
    await t.runAsync(() => Future.wait([
          rootBundle.loadString('assets/data/bible_verses_ko.json'),
          rootBundle.loadString('assets/data/content_release_baseline.json')
        ]));
    final client = ExampleClient();
    await t.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: ConversationPage(
            animateComposerBorder: false,
            emotion: EmotionType.joy,
            intensity: 5,
            apiClient: client)));
    await t.pump(const Duration(milliseconds: 500));
    expect(choices(), findsNWidgets(5));
    final selected = t.widget(choices().first).key;
    await t.ensureVisible(choices().first);
    await t.tap(choices().first);
    for (var i = 0; i < 80; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump(const Duration(milliseconds: 30));
      if (client.calls == 1 && choices().evaluate().length == 5) break;
    }
    expect(client.calls, 1);
    expect(choices(), findsNWidgets(5));
    expect(find.byKey(selected!), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
      'three safe manual messages create a personal topic through the real conversation',
      (t) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = null);
    await SharedPreferencesAsync()
        .setString(AiConsent.preferenceKey, AiConsent.version);
    for (final channel in [
      'flutter_tts',
      'plugin.csdcorp.com/speech_to_text'
    ]) {
      t.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (_) async => 1);
    }
    rootBundle.clear();
    await t.runAsync(() => Future.wait([
          rootBundle.loadString('assets/data/bible_verses_ko.json'),
          rootBundle.loadString('assets/data/content_release_baseline.json')
        ]));
    final learning = PersonalKeywordLearning();
    await t.runAsync(() => Future.wait([
          rootBundle.loadString('assets/data/bible_verses_ko.json'),
          rootBundle.loadString('assets/data/content_release_baseline.json')
        ]));
    final client = ExampleClient();
    await t.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: ConversationPage(
            animateComposerBorder: false,
            emotion: EmotionType.anxiety,
            intensity: 5,
            apiClient: client,
            keywordLearning: learning)));
    await t.pump(const Duration(milliseconds: 500));
    for (var turn = 1; turn <= 3; turn++) {
      await t.enterText(find.byType(TextField), '회사 업무를 이야기하고 싶어요.');
      await t.tap(find.byTooltip('보내기'));
      for (var i = 0; i < 80; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await t.pump(const Duration(milliseconds: 30));
        if (client.calls >= turn &&
            (turn == 3 || choices().evaluate().length == 5)) break;
      }
      if (turn < 3) await t.pumpAndSettle();
    }
    expect(client.calls, 3);
    expect(learning.cards, contains('업무'));
    expect(learning.examples('불안'), isNotEmpty);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
