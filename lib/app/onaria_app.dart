import 'dart:async';
import 'package:flutter/material.dart';

import '../engagement/engagement_controller.dart';
import '../engagement/engagement_page.dart';
import '../engagement/notifications/reminder_controller.dart';
import '../features/check_in_page.dart';
import '../features/account_menu.dart';
import 'app_theme.dart';
import 'social_auth_config.dart';
import 'theme_controller.dart';
import 'member_record_scope.dart';

class OnariaApp extends StatefulWidget {
  const OnariaApp({
    super.key,
    this.authConfig = const SocialAuthConfig(),
    this.engagement,
    this.homeOverride,
  });

  final SocialAuthConfig authConfig;
  final EngagementController? engagement;
  final Widget? homeOverride;

  @override
  State<OnariaApp> createState() => _OnariaAppState();
}

class _OnariaAppState extends State<OnariaApp> with WidgetsBindingObserver {
  final _theme = ThemeController();
  var _navigator = GlobalKey<NavigatorState>();
  late var _engagement = widget.engagement ?? EngagementController();

  @override
  void initState() {
    super.initState();
    MemberRecordScope.instance.addListener(_recordAccountChanged);
    _theme.load();
    WidgetsBinding.instance.addObserver(this);
    _engagement.reminders.onTap = _openReminder;
    unawaited(_engagement.load());
    unawaited(_engagement.visit());
  }

  void _recordAccountChanged() {
    if (!mounted) return;
    // Discard routes, controllers and in-memory summaries from the old account.
    final old = _engagement;
    old.reminders.onTap = null;
    unawaited(old.reminders.gateway.cancelAll().catchError((Object _) {}));
    if (widget.engagement == null) old.dispose();
    setState(() {
      _navigator = GlobalKey<NavigatorState>();
      _engagement = widget.engagement ?? EngagementController();
    });
    _engagement.reminders.onTap = _openReminder;
    unawaited(_engagement.load());
  }

  void _openReminder(ReminderKind kind) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _engagement.reminders.settings.paused) return;
      final navigator = _navigator.currentState;
      if (kind == ReminderKind.checkin || kind == ReminderKind.gentle) {
        // Keep an ongoing conversation intact when returning from a reminder.
        if (navigator?.canPop() == true) return;
      } else {
        navigator?.push(MaterialPageRoute<void>(
            builder: (_) => EngagementPage(
                  savedOnly: kind == ReminderKind.savedVerses,
                )));
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_engagement.visit());
  }

  @override
  Future<bool> didPushRouteInformation(
      RouteInformation routeInformation) async {
    final uri = routeInformation.uri;
    // An invitation opens the app without replacing an ongoing conversation.
    return (uri.scheme == 'https' &&
            uri.host == 'api.onaria.ai.kr' &&
            uri.path == '/app/open') ||
        (uri.scheme == 'onaria' && uri.host == 'app' && uri.path == '/open') ||
        (uri.scheme.isEmpty && uri.path == '/app/open');
  }

  @override
  void dispose() {
    MemberRecordScope.instance.removeListener(_recordAccountChanged);
    _theme.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _engagement.reminders.onTap = null;
    if (widget.engagement == null) _engagement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EngagementScope(
        controller: _engagement,
        child: ValueListenableBuilder<ThemeColor>(
            valueListenable: _theme,
            builder: (context, color, child) => MaterialApp(
                  title: 'ONARIA',
                  navigatorKey: _navigator,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.forColor(color),
                  home: widget.homeOverride ??
                      (MemberRecordScope.instance.locked
                          ? const Scaffold(
                              body: SafeArea(
                                child: Column(children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: AccountMenuButton(),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Text(
                                          '계정을 확인한 뒤 기록을 열 수 있어요.\n메뉴에서 로그인 상태를 다시 확인해 주세요.',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            )
                          : const CheckInPage()),
                  initialRoute: '/',
                )));
  }
}
