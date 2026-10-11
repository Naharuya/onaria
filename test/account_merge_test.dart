import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onaria/app/member_session_store.dart';
import 'package:onaria/app/member_record_scope.dart';
import 'package:onaria/app/merged_record_reader.dart';
import 'package:onaria/app/member_record_cleanup.dart';
import 'package:onaria/features/account_merge_page.dart';
import 'package:onaria/src/api/provider_auth_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class Persistence implements MemberSessionPersistence {
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

Map<String, Object> plan() => {
      'attemptToken': 'B' * 43,
      'targetId': 1,
      'sourceId': 2,
      'providers': ['google', 'naver'],
      'recordOwnerIds': [1, 2],
      'expiresAt': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 2))
          .millisecondsSinceEpoch
    };
void main() {
  test('confirmed family cleanup resumes and excludes outsiders', () async {
    final prefs = SharedPreferencesAsync();
    for (final id in [1, 2, 3]) {
      await prefs.setString('onaria.records.v2.member.$id.fixture', 'fixture');
    }
    await prefs.setString('soul_bible.mind_cards.v1', 'legacy');
    final cleanup = MemberRecordCleanup(preferences: prefs);
    await cleanup.markServerDeletedMany([1, 2]);
    await cleanup.retry(1);
    await MemberRecordCleanup(preferences: prefs).retryConfirmed();
    expect(await prefs.getString('onaria.records.v2.member.1.fixture'), isNull);
    expect(await prefs.getString('onaria.records.v2.member.2.fixture'), isNull);
    expect(
        await prefs.getString('onaria.records.v2.member.3.fixture'), 'fixture');
    expect(await prefs.getString('soul_bible.mind_cards.v1'), 'legacy');
  });

  testWidgets(
      'merge confirmation stays reachable on a small screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = MemberSessionStore.forTesting(Persistence())
      ..set(token: 'A' * 43, expiresInSeconds: 3600);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: AccountMergePage(
            sessionStore: session,
            credentialLoader: (_) async => 'fixture',
            apiClientFactory: (base) => ProviderAuthApiClient(
                baseUrl: base,
                httpClient: MockClient((request) async {
                  if (request.method == 'GET')
                    return http.Response(
                        '{"member":{"id":1},"providers":["google"],"currentProvider":"google","mergeAvailable":true}',
                        200);
                  return http.Response(jsonEncode(plan()), 201);
                })))));
    await tester.scrollUntilVisible(find.text('두 계정 확인하기'), 200);
    await tester.tap(find.text('두 계정 확인하기'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('merge-consent')), 200);
    await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('merge-consent'))),
        alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('merge-consent')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('merge-confirm')), 200);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('merge-confirm')))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    MemberRecordScope.instance.verified(1);
  });
  tearDown(() {
    MemberRecordScope.instance.signedOut();
    SharedPreferencesAsyncPlatform.instance = null;
  });
  test(
      'malformed ownership cannot enable access and old server falls back to current owner',
      () async {
    for (final owners in [
      [2],
      [1, 1],
      [1, -2],
      [1, '2']
    ]) {
      final api = ProviderAuthApiClient(
          baseUrl: Uri.parse('https://api.onaria.ai.kr'),
          httpClient: MockClient((_) async => http.Response(
              jsonEncode({
                'member': {'id': 1},
                'providers': ['google'],
                'currentProvider': 'google',
                'recordOwnerIds': owners
              }),
              200)));
      await expectLater(api.account('A' * 43), throwsFormatException);
      api.close();
    }
    final api = ProviderAuthApiClient(
        baseUrl: Uri.parse('https://api.onaria.ai.kr'),
        httpClient: MockClient((_) async => http.Response(
            '{"member":{"id":1},"providers":["google"],"currentProvider":"google"}',
            200)));
    final account = await api.account('A' * 43);
    expect(account.mergeAvailable, false);
    expect(account.recordOwnerIds, [1]);
    api.close();
  });
  test(
      'archived records use server owners only; original, guest and unrelated data remain untouched',
      () async {
    final session = MemberSessionStore.forTesting(Persistence())
      ..set(token: 'A' * 43, expiresInSeconds: 3600);
    final prefs = SharedPreferencesAsync();
    await prefs.setString('onaria.records.v2.member.2.onaria.unsent_draft.v1',
        '{"text":"owned source"}');
    await prefs.setString('onaria.records.v2.member.3.onaria.unsent_draft.v1',
        '{"text":"other member"}');
    await prefs.setString(
        'onaria.records.v2.guest.onaria.unsent_draft.v1', '{"text":"guest"}');
    await prefs.setString('onaria.unsent_draft.v1', '{"text":"legacy"}');
    await prefs.setStringList(
        'onaria.records.v2.member.2.soul_bible.mind_cards.v1',
        ['damaged original']);
    final before = await prefs.getKeys();
    final api = ProviderAuthApiClient(
        baseUrl: Uri.parse('https://api.onaria.ai.kr'),
        httpClient: MockClient((_) async => http.Response(
            '{"member":{"id":1},"providers":["google","naver"],"currentProvider":"google","recordOwnerIds":[1,2]}',
            200)));
    final archives = await MergedRecordReader(
            client: api, sessions: session, preferences: prefs)
        .load();
    expect(archives.single.draft, 'owned source');
    expect(archives.single.unreadableItems, 1);
    expect(await prefs.getKeys(), before);
    expect(
        await prefs.getStringList(
            'onaria.records.v2.member.2.soul_bible.mind_cards.v1'),
        ['damaged original']);
    api.close();
    session.dispose();
  });
  test(
      'archive lookup rejects a changed account without returning source content',
      () async {
    final session = MemberSessionStore.forTesting(Persistence())
      ..set(token: 'A' * 43, expiresInSeconds: 3600);
    final api = ProviderAuthApiClient(
        baseUrl: Uri.parse('https://api.onaria.ai.kr'),
        httpClient: MockClient((_) async {
          MemberRecordScope.instance.verified(3);
          return http.Response(
              '{"member":{"id":1},"providers":["google"],"currentProvider":"google","recordOwnerIds":[1,2]}',
              200);
        }));
    await expectLater(MergedRecordReader(client: api, sessions: session).load(),
        throwsStateError);
    api.close();
    session.dispose();
  });
  for (final failure in [false, true]) {
    testWidgets(
        'optional merge requires two proofs and consent; uncertain=$failure',
        (tester) async {
      final session = MemberSessionStore.forTesting(Persistence())
        ..set(token: 'A' * 43, expiresInSeconds: 3600);
      final proofs = <String>[];
      var confirms = 0;
      await tester.pumpWidget(MaterialApp(
          home: AccountMergePage(
              sessionStore: session,
              credentialLoader: (provider) async {
                proofs.add(provider);
                return 'synthetic proof';
              },
              apiClientFactory: (base) => ProviderAuthApiClient(
                  baseUrl: base,
                  httpClient: MockClient((request) async {
                    if (request.url.path == '/v1/account')
                      return http.Response(
                          '{"member":{"id":1},"providers":["google"],"currentProvider":"google","recordOwnerIds":[1],"mergeAvailable":true}',
                          200);
                    if (request.url.path.endsWith('/prepare')) {
                      expect(proofs, ['google', 'naver']);
                      final body = jsonDecode(request.body);
                      expect(body['reauthProvider'], 'google');
                      expect(body['sourceProvider'], 'naver');
                      expect(request.url.query, isEmpty);
                      return http.Response(jsonEncode(plan()), 201);
                    }
                    confirms++;
                    if (failure)
                      return http.Response(
                          '{"code":"MERGE_STATUS_RECHECK_REQUIRED","message":"fixture"}',
                          503);
                    return http.Response(
                        jsonEncode({
                          'completed': true,
                          'targetId': 1,
                          'sourceId': 2,
                          'recordOwnerIds': [1, 2],
                          'sessionToken': 'C' * 43,
                          'expiresInSeconds': 3600
                        }),
                        200);
                  })))));
      await tester.tap(find.text('두 계정 확인하기'));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('merge-confirm'));
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(confirms, 0);
      await tester.ensureVisible(find.byKey(const ValueKey('merge-consent')));
      await tester.tap(find.byKey(const ValueKey('merge-consent')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(confirms, 1);
      if (failure) {
        expect(find.textContaining('통합 결과를 아직 확인할 수 없어요.'), findsOneWidget);
        expect(find.byKey(const ValueKey('merge-confirm')), findsNothing);
        expect(session.token, 'A' * 43);
      } else {
        expect(session.token, 'C' * 43);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    });
  }
  testWidgets('cancelled authentication never submits or merges',
      (tester) async {
    final session = MemberSessionStore.forTesting(Persistence())
      ..set(token: 'A' * 43, expiresInSeconds: 3600);
    var requests = 0;
    await tester.pumpWidget(MaterialApp(
        home: AccountMergePage(
            sessionStore: session,
            credentialLoader: (_) async =>
                throw StateError('fixture cancellation'),
            apiClientFactory: (base) => ProviderAuthApiClient(
                baseUrl: base,
                httpClient: MockClient((_) async {
                  requests++;
                  return http.Response(
                      '{"member":{"id":1},"providers":["google"],"currentProvider":"google","mergeAvailable":true}',
                      200);
                })))));
    await tester.tap(find.text('두 계정 확인하기'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.byKey(const ValueKey('merge-confirm')), findsNothing);
    expect(session.token, 'A' * 43);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
}
