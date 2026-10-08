import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/app/member_session_store.dart';
import 'package:onaria/app/member_registration_store.dart';
import 'package:onaria/features/privacy_page.dart';
import 'package:onaria/src/api/provider_auth_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Persistence implements MemberSessionPersistence {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class _FailingRegistrationStore extends MemberRegistrationStore {
  @override
  Future<void> clear() async =>
      throw StateError('simulated local storage failure');
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty());
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);
  for (final scenario in [
    'lookup-failure',
    'deletion-failure',
    'success',
    'metadata-failure',
    'fresh-apple-proof-failure'
  ]) {
    testWidgets('account deletion $scenario preserves or clears correct data',
        (tester) async {
      final session = MemberSessionStore.forTesting(_Persistence());
      session.set(
          token: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ',
          expiresInSeconds: 3600);
      final prefs = SharedPreferencesAsync();
      await MemberRegistrationStore().saveMemberId(123);
      await prefs.setString('soul_bible.mind_cards.v1', 'saved-personal-card');
      await prefs.setString('onaria.unsent_draft.v1', 'unsent-personal-draft');
      var accountCalls = 0;
      var deletes = 0;
      var appleProofs = 0;
      await tester.pumpWidget(MaterialApp(
          home: PrivacyPage(
              sessionStore: session,
              registrationStore: scenario == 'metadata-failure'
                  ? _FailingRegistrationStore()
                  : null,
              appleDeletionCredential: () async {
                appleProofs++;
                throw StateError('simulated cancelled Apple reauthentication');
              },
              apiClientFactory: (base) => ProviderAuthApiClient(
                  baseUrl: base,
                  httpClient: MockClient((request) async {
                    if (request.method == 'GET') {
                      accountCalls++;
                      if (scenario == 'fresh-apple-proof-failure' &&
                          accountCalls == 1) {
                        return http.Response('{}', 503);
                      }
                      if (scenario == 'fresh-apple-proof-failure') {
                        return http.Response(
                            '{"providers":["apple"],"currentProvider":"apple"}',
                            200);
                      }
                      if (scenario == 'lookup-failure' && accountCalls > 1) {
                        return http.Response('{}', 503);
                      }
                      return http.Response(
                          '{"providers":["naver"],"currentProvider":"naver"}',
                          200);
                    }
                    deletes++;
                    return http.Response(
                        '', scenario == 'deletion-failure' ? 503 : 204);
                  })))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('account-deletion')), 350);
      await tester.tap(find.byKey(const ValueKey('account-deletion')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, '회원탈퇴')));
      await tester.pumpAndSettle();
      expect(accountCalls, 2,
          reason: 'Deletion must freshly verify linked providers.');
      expect(
          deletes,
          ['lookup-failure', 'fresh-apple-proof-failure'].contains(scenario)
              ? 0
              : 1);
      expect(appleProofs, scenario == 'fresh-apple-proof-failure' ? 1 : 0);
      if (scenario == 'success' || scenario == 'metadata-failure') {
        expect(session.token, isNull);
        expect(await MemberRegistrationStore().loadMemberId(),
            scenario == 'metadata-failure' ? 123 : null);
        expect(find.byKey(const ValueKey('account-deletion')), findsNothing);
        expect(find.text('현재 로그인'), findsNothing);
        expect(
            find.text(scenario == 'metadata-failure'
                ? '회원탈퇴가 완료되었어요. 이 기기의 회원 번호 정리는 다시 시도해 주세요.'
                : '회원탈퇴가 완료되었어요.'),
            findsOneWidget);
      } else {
        expect(session.token, isNotNull);
        expect(await MemberRegistrationStore().loadMemberId(), 123);
        expect(find.byKey(const ValueKey('account-deletion')), findsOneWidget);
      }
      expect(await prefs.getString('soul_bible.mind_cards.v1'),
          'saved-personal-card');
      expect(await prefs.getString('onaria.unsent_draft.v1'),
          'unsent-personal-draft');
    });
  }
}
