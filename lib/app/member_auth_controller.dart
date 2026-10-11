import 'dart:async';

import 'package:flutter/foundation.dart';

import '../src/api/provider_auth_api_client.dart';
import '../src/auth/naver_login_service.dart';
import 'member_session_store.dart';
import 'member_record_scope.dart';

enum MemberAuthState { checking, signedOut, signedIn, unavailable }

class MemberAuthController extends ChangeNotifier {
  MemberAuthController({
    required this.sessions,
    required this.clientFactory,
    Future<void> Function()? signOutNaver,
  }) : _signOutNaver = signOutNaver ?? NaverLoginService().signOut {
    sessions.addListener(_sessionChanged);
  }

  final MemberSessionStore sessions;
  final ProviderAuthApiClient Function() clientFactory;
  final Future<void> Function() _signOutNaver;
  MemberAuthState state = MemberAuthState.checking;
  String? provider;
  bool busy = false;
  bool _disposed = false;
  int _generation = 0;
  Timer? _expiry;

  String get label => switch (state) {
        MemberAuthState.checking => '확인 중',
        MemberAuthState.signedOut =>
          sessions.cleanupFailed ? '로그아웃됨 · 기기 정리 필요' : '로그인하지 않음',
        MemberAuthState.unavailable => '로그인 상태 확인 불가',
        MemberAuthState.signedIn => switch (provider) {
            'naver' => '로그인됨 · 네이버',
            'google' => '로그인됨 · Google',
            'apple' => '로그인됨 · Apple',
            'kakao' => '로그인됨 · 카카오',
            _ => '로그인됨',
          },
      };

  void _sessionChanged() => unawaited(refresh());

  Future<void> refresh() async {
    if (_disposed) return;
    final generation = ++_generation;
    final token = sessions.token;
    _expiry?.cancel();
    provider = null;
    if (token == null) {
      state = sessions.restorationFailed
          ? MemberAuthState.unavailable
          : MemberAuthState.signedOut;
      notifyListeners();
      return;
    }
    final expiresAt = sessions.expiresAt;
    if (expiresAt != null) {
      _expiry = Timer(expiresAt.difference(DateTime.now().toUtc()), () {
        // A newer session owns a different generation and its own timer.
        if (!_disposed && sessions.token == null) sessions.clear();
      });
    }
    state = MemberAuthState.checking;
    notifyListeners();
    ProviderAuthApiClient? client;
    try {
      client = clientFactory();
      final account = await client.account(token);
      if (!_isCurrent(generation, token)) return;
      if (identical(sessions, MemberSessionStore.instance)) {
        if (account.memberId == null)
          throw const FormatException('Invalid member identity');
        MemberRecordScope.instance.verified(account.memberId!);
      }
      provider = account.currentProvider;
      state = MemberAuthState.signedIn;
    } on ProviderAuthApiException catch (error) {
      if (!_isCurrent(generation, token)) return;
      if (error.statusCode == 401 || error.statusCode == 404) {
        sessions.clear();
        return;
      }
      state = MemberAuthState.unavailable;
    } catch (_) {
      if (!_isCurrent(generation, token)) return;
      state = MemberAuthState.unavailable;
    } finally {
      client?.close();
    }
    if (!_disposed && generation == _generation) notifyListeners();
  }

  bool _isCurrent(int generation, String token) =>
      !_disposed && generation == _generation && sessions.token == token;

  Future<void> retry() async {
    if (sessions.restorationFailed) {
      state = MemberAuthState.checking;
      notifyListeners();
      await sessions.restore();
    }
    await refresh();
  }

  Future<bool> logout() async {
    if (busy || _disposed) return false;
    final token = sessions.token;
    if (token == null) {
      if (sessions.cleanupFailed) sessions.clear();
      final cleared = await sessions.flush();
      await refresh();
      return cleared;
    }
    final previousProvider = provider;
    busy = true;
    notifyListeners();
    ProviderAuthApiClient? client;
    try {
      client = clientFactory();
      try {
        await client.logout(token);
      } on ProviderAuthApiException catch (error) {
        // An already-invalid server session can be cleared locally.
        if (error.statusCode != 401) rethrow;
      }
      if (_disposed || sessions.token != token) return false;
      sessions.clear();
      final locallyCleared = await sessions.flush();
      if (previousProvider == 'naver') {
        try {
          await _signOutNaver();
        } catch (_) {
          // Server logout remains successful. Naver login retries SDK cleanup.
        }
      }
      return locallyCleared;
    } finally {
      client?.close();
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _expiry?.cancel();
    sessions.removeListener(_sessionChanged);
    super.dispose();
  }
}
