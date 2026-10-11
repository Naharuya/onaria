import 'package:flutter/material.dart';

import 'app/kakao_auth_config.dart';
import 'app/member_session_store.dart';
import 'app/member_record_cleanup.dart';
import 'app/onaria_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KakaoAuthConfig.initialize();
  try { await MemberRecordCleanup().retryConfirmed(); } catch (_) { /* Retry on next startup; never gate safety. */ }
  await MemberSessionStore.instance.restore();
  runApp(const OnariaApp());
}
